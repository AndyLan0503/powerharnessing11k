#!/usr/bin/env bash
# After a file edit: formats the file the agent just changed.
# Never fails the tool call: a missing formatter is not the agent's problem.
. "$(dirname "$0")/lib.sh"

fmt='{{FORMAT_CMD}}'
cwd=$(hook_cwd)
cd "$(hook_root)" || exit 0
hook_files | while IFS= read -r file; do
  [ -n "$file" ] || continue
  case $file in /*) ;; *) file=$cwd/$file ;; esac
  [ -f "$file" ] || continue
  quoted=$(printf '%q' "$file")
  eval "${fmt//\{file\}/$quoted}" >/dev/null 2>&1 || true
done
exit 0
