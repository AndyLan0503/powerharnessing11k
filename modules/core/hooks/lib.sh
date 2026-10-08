#!/usr/bin/env bash
# Shared helpers for this repo's agent hooks (.agents/hooks/).
#
# Every hook is called as `<script> <agent>` with the agent's JSON payload on
# stdin. Agents name their payload fields and signal a block differently; the
# hook_* accessors below hide that, so the guard logic is written once.
#
# Works without jq: falls back to python3, then to a sed extractor that is
# good enough for pattern matching.

HOOK_AGENT=${1:-claude}
HOOK_INPUT=$(cat)
HOOK_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# hook_field KEY: string value of tool_input.KEY, else top-level KEY.
hook_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r --arg k "$1" \
      '((.tool_input // {})[$k] // .[$k]) // empty | if type == "string" then . else tojson end' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import json, sys
d = json.load(sys.stdin); k = sys.argv[1]
v = (d.get("tool_input") or {}).get(k, d.get(k))
print("" if v is None else v if isinstance(v, str) else json.dumps(v))' "$1" 2>/dev/null
  else
    printf '%s' "$HOOK_INPUT" | tr -d '\n' |
      sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\\1/p" | head -n 1
  fi
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

# What the agent is about to do, or just did. One case per agent; an agent
# not listed uses the first set of field names.
hook_command() { # the shell command
  case $HOOK_AGENT in
    *) hook_field command ;;
  esac
}
hook_files() { # the files being created or edited, one per line
  local f
  case $HOOK_AGENT in
    codex)
      # Edits arrive as one apply_patch call: the patch text is in
      # tool_input.command and names each file on a "*** ... File:" line.
      # (Without jq or python3 the text still has \n escapes; awk splits both.)
      # Codex trims these header lines, so do the same: a carriage return or
      # stray blanks around the path must not hide which file is meant.
      hook_field command | awk '
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
      ;;
    *)
      f=$(hook_field file_path)
      [ -n "$f" ] || f=$(hook_field notebook_path)
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
hook_tool() {
  case $HOOK_AGENT in
    *) hook_field tool_name ;;
  esac
}
hook_session() {
  case $HOOK_AGENT in
    *) hook_field session_id ;;
  esac
}
# 0 when this call is the agent finishing its turn.
hook_is_stop() {
  case $HOOK_AGENT in
    *) [ "$(hook_field hook_event_name)" = Stop ] ;;
  esac
}
# 0 when the agent is already continuing because a stop hook sent it back.
hook_stop_active() {
  case $HOOK_AGENT in
    *) [ "$(hook_field stop_hook_active)" = true ] ;;
  esac
}

_hook_esc() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s" | tr '\n\t\r' '   '
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
  hook_log blocked "$1"
  _hook_refuse "Blocked by guardrail: $1
If this is genuinely required, stop and ask a human to do it."
}

# hook_send_back MESSAGE: the agent was about to finish; make it continue.
hook_send_back() { _hook_refuse "$1"; }

# How each agent is told "no". Exit code 2 with the reason on stderr.
_hook_refuse() {
  case $HOOK_AGENT in
    *)
      printf '%s\n' "$1" >&2
      exit 2
      ;;
  esac
}
