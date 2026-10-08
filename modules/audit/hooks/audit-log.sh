#!/usr/bin/env bash
# After every tool call and at the end of a turn: appends a compact record of
# each agent action to .agents/logs/events.jsonl (git-ignored). Inputs are truncated; tool output
# is never logged.
. "$(dirname "$0")/lib.sh"

if hook_is_stop; then
  hook_log turn_end ""
else
  # For a file edit, log the files; for anything else, the command.
  detail=$(hook_files | tr '\n' ' ')
  detail=${detail% }
  [ -n "$detail" ] || detail=$(hook_command)
  [ -n "$detail" ] || detail=$(hook_field pattern)
  [ -n "$detail" ] || detail=$(hook_field url)
  hook_log tool "$(printf '%s' "$detail" | cut -c 1-300)"
fi
exit 0
