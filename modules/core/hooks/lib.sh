#!/usr/bin/env bash
# Shared helpers for this repo's agent hooks (.agents/hooks/).
#
# Every hook is called as `<script> <agent>` with the agent's JSON payload on
# stdin. Agents name their payload fields and signal a block differently; the
# hook_* accessors below hide that, so the guard logic is written once.
#
#   claude, codex   tool_name, tool_input.{command,file_path}, session_id;
#                   exit 2 with the reason on stderr blocks.
#   copilot         toolName, toolArgs (an object, or a JSON string holding
#                   one), sessionId; a JSON decision on stdout blocks.
#
# Works without jq: falls back to python3, then to a sed extractor that is
# good enough for pattern matching.

HOOK_AGENT=${1:-claude}
HOOK_INPUT=$(cat)
HOOK_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# hook_field KEY: string value of KEY in the tool's arguments, else at the
# top level of the payload. The arguments are tool_input or toolArgs.
hook_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r --arg k "$1" '
      def args: (.tool_input // .toolArgs // {})
        | if type == "string" then (fromjson? // {}) else . end
        | if type == "object" then . else {} end;
      (args[$k] // .[$k]) // empty | if type == "string" then . else tojson end' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import json, sys
d = json.load(sys.stdin); k = sys.argv[1]
a = d.get("tool_input", d.get("toolArgs")) or {}
if isinstance(a, str):
    try: a = json.loads(a)
    except ValueError: a = {}
if not isinstance(a, dict): a = {}
v = a.get(k, d.get(k))
print("" if v is None else v if isinstance(v, str) else json.dumps(v))' "$1" 2>/dev/null
  else
    # Arguments sent as a JSON string have their quotes escaped; undo one
    # level so the extractor can see the keys inside.
    printf '%s' "$HOOK_INPUT" | tr -d '\n' |
      sed -E '/"toolArgs"[[:space:]]*:[[:space:]]*"/ s/\\(["\\])/\1/g' |
      sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\\1/p" | head -n 1
  fi
}

# hook_top KEY: string value of KEY at the top level of the payload only.
hook_top() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r --arg k "$1" '.[$k] // empty | if type == "string" then . else tojson end' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import json, sys
v = json.load(sys.stdin).get(sys.argv[1])
print("" if v is None else v if isinstance(v, str) else json.dumps(v))' "$1" 2>/dev/null
  else
    hook_field "$1"
  fi
}

# _hook_first KEY...: the first of these fields that has a value.
_hook_first() {
  local k v
  for k in "$@"; do
    v=$(hook_field "$k")
    if [ -n "$v" ]; then
      printf '%s' "$v"
      return 0
    fi
  done
}

hook_root() { printf '%s' "$HOOK_ROOT"; }

# hook_rel PATH: where PATH really is, relative to the repo root. Symlinks and
# ".." in existing directories are resolved, so a protected file cannot be
# reached under another name (for example through the .claude/skills link).
# Parts that do not exist yet are kept as written.
hook_rel() {
  local p=$1 dir rest='' real_dir real_root
  case $p in /*) ;; *) p=$(hook_cwd)/$p ;; esac
  dir=$(dirname "$p")
  while [ ! -d "$dir" ] && [ "$dir" != / ]; do
    rest="${dir##*/}/$rest"
    dir=$(dirname "$dir")
  done
  real_dir=$(cd "$dir" 2>/dev/null && pwd -P) || real_dir=$dir
  real_root=$(cd "$HOOK_ROOT" && pwd -P)
  p=${real_dir%/}/$rest${p##*/}
  case $p in "$real_root"/*) p=${p#"$real_root"/} ;; esac
  printf '%s' "$p"
}

# The shell command about to run, or just run.
hook_command() { hook_field command; }

# File names out of a patch in the apply_patch format ("*** Update File: p"),
# read from stdin. The format's own parser trims these header lines, so do the
# same: a carriage return or stray blanks around the path must not hide which
# file is meant. (Without jq or python3 the text still has \n escapes; awk
# splits on both.)
_hook_patch_files() {
  awk '
    { n = split($0, lines, /\\n/)
      for (i = 1; i <= n; i++) {
        l = lines[i]
        gsub(/\\r|\r/, "", l)
        sub(/^[ \t]+/, "", l); sub(/[ \t]+$/, "", l)
        if (l ~ /^\*\*\* (Add|Update|Delete) File:/) sub(/^\*\*\* [A-Za-z]+ File:[ \t]*/, "", l)
        else if (l ~ /^\*\*\* Move to:/) sub(/^\*\*\* Move to:[ \t]*/, "", l)
        else continue
        if (l != "") print l
      } }'
}

# The files being created or edited, one per line.
hook_files() {
  local f
  case $HOOK_AGENT in
    codex)
      # Every edit is one apply_patch call with the patch in tool_input.command.
      hook_field command | _hook_patch_files
      ;;
    copilot)
      # Edit tools name the file in "path"; some models edit through
      # apply_patch instead, with the patch as the argument.
      f=$(
        f=$(_hook_first path file_path filePath notebook_path)
        [ -z "$f" ] || printf '%s\n' "$f"
        _hook_first patch input command | _hook_patch_files
      )
      # The argument names of the edit tools are not documented, and a patch
      # may arrive as bare text. If nothing was recognised, look for patch
      # headers anywhere in the payload, so an edit is never waved through
      # only because of how it was wrapped.
      [ -n "$f" ] || f=$(printf '%s' "$HOOK_INPUT" | _hook_patch_files | sed 's/["}\\]*$//')
      [ -z "$f" ] || printf '%s\n' "$f"
      ;;
    *)
      f=$(_hook_first file_path notebook_path)
      printf '%s\n' "$f"
      ;;
  esac
}

# The directory relative paths in the payload are relative to.
hook_cwd() {
  local d
  d=$(hook_field cwd)
  [ -n "$d" ] && [ -d "$d" ] || d=$HOOK_ROOT
  printf '%s' "$d"
}
hook_tool() { _hook_first tool_name toolName; }
hook_session() { _hook_first session_id sessionId; }

# 0 when this call is the agent finishing its turn.
hook_is_stop() {
  case $(hook_top hook_event_name) in Stop | agentStop) return 0 ;; esac
  # Copilot's payload names no event; only the end of a turn has a stop
  # reason (at the top level: a tool argument of that name does not count).
  [ -z "$(hook_tool)" ] && [ -n "$(hook_top stopReason)" ]
}
# 0 when the agent is already continuing because a stop hook sent it back.
hook_stop_active() { [ "$(hook_field stop_hook_active)" = true ]; }

_hook_esc() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s" | tr '\n\t\r' '   '
}

# A value as the inside of a JSON string, newlines kept as \n. Only printable
# ASCII is kept: tool output can hold bytes that are not valid UTF-8, and one
# such byte would make the whole answer unreadable to the agent.
_hook_json_str() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s" | LC_ALL=C tr '\t\r' '  ' | LC_ALL=C tr -cd '\040-\176'
}

# hook_log KIND DETAIL: append one JSON line to .agents/logs/events.jsonl.
hook_log() {
  local dir
  dir="$HOOK_ROOT/.agents/logs"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '{"ts":"%s","kind":"%s","session_id":"%s","tool":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" \
    "$(_hook_esc "$(hook_session)")" \
    "$(_hook_esc "$(hook_tool)")" \
    "$(_hook_esc "$2")" >>"$dir/events.jsonl" 2>/dev/null || true
}

# hook_block REASON: log, then block the tool call and tell the agent why.
hook_block() {
  local msg
  hook_log blocked "$1"
  msg="Blocked by guardrail: $1
If this is genuinely required, stop and ask a human to do it."
  printf '%s\n' "$msg" >&2
  case $HOOK_AGENT in
    copilot)
      # The documented way to deny is a JSON decision on stdout. A non-zero
      # exit also denies, so the block holds even if the JSON is not read.
      printf '{"permissionDecision":"deny","permissionDecisionReason":"%s"}\n' "$(_hook_json_str "$msg")"
      ;;
  esac
  exit 2
}

# hook_send_back MESSAGE: the agent was about to finish; make it continue with
# MESSAGE as what to do next.
hook_send_back() {
  printf '%s\n' "$1" >&2
  case $HOOK_AGENT in
    copilot)
      printf '{"decision":"block","reason":"%s"}\n' "$(_hook_json_str "$1")"
      exit 0
      ;;
  esac
  exit 2
}
