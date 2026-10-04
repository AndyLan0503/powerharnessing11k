#!/usr/bin/env bash
# PostToolUse(*) and Stop: appends a compact record of each agent action to
# .harness/logs/events.jsonl (git-ignored). Inputs are truncated; tool output
# is never logged.
. "$(dirname "$0")/lib.sh"

event=$(hook_field hook_event_name)
case $event in
  Stop) hook_log turn_end "" ;;
  *)
    detail=$(hook_field command)
    [ -n "$detail" ] || detail=$(hook_field file_path)
    [ -n "$detail" ] || detail=$(hook_field pattern)
    [ -n "$detail" ] || detail=$(hook_field url)
    hook_log tool "$(printf '%s' "$detail" | cut -c 1-300)"
    ;;
esac
exit 0
