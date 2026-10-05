#!/usr/bin/env bash
# Shared helpers for this repo's Claude Code hooks (.claude/hooks/).
#
# Works without jq: falls back to python3, then to a sed extractor that is
# good enough for pattern matching.

HOOK_INPUT=$(cat)

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

hook_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

_hook_esc() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s" | tr '\n\t\r' '   '
}

# hook_log KIND DETAIL: append one JSON line to .claude/logs/events.jsonl.
hook_log() {
  local dir
  dir="$(hook_root)/.claude/logs"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '{"ts":"%s","kind":"%s","session_id":"%s","tool":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" \
    "$(_hook_esc "$(hook_field session_id)")" \
    "$(_hook_esc "$(hook_field tool_name)")" \
    "$(_hook_esc "$2")" >>"$dir/events.jsonl" 2>/dev/null || true
}

# hook_block REASON: log, then block the tool call. Exit code 2 sends stderr
# back to the agent as the reason.
hook_block() {
  hook_log blocked "$1"
  printf 'Blocked by guardrail: %s\nIf this is genuinely required, stop and ask a human to do it.\n' "$1" >&2
  exit 2
}
