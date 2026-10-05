#!/usr/bin/env bash
# After a file edit: formats the file the agent just changed.
# Never fails the tool call: a missing formatter is not the agent's problem.
. "$(dirname "$0")/lib.sh"

file=$(hook_file)
[ -n "$file" ] && [ -f "$file" ] || exit 0
cd "$(hook_root)" || exit 0

fmt='{{FORMAT_CMD}}'
quoted=$(printf '%q' "$file")
eval "${fmt//\{file\}/$quoted}" >/dev/null 2>&1 || true
exit 0
