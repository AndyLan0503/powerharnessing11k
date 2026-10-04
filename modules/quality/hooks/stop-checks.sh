#!/usr/bin/env bash
# Stop: when the working tree has changes, run fast checks before the agent
# finishes its turn. On failure, exit 2 sends the output back so the agent
# fixes it. stop_hook_active guards against looping forever.
. "$(dirname "$0")/lib.sh"

[ "$(hook_field stop_hook_active)" = "true" ] && exit 0
cd "$(hook_root)" || exit 0
[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0

out=$(mktemp)
trap 'rm -f "$out"' EXIT
failed=''
{{#if LINT_CMD}}
if ! {{LINT_CMD}} >"$out" 2>&1; then failed="lint ({{LINT_CMD}})"; fi
{{/if}}
{{#if TYPECHECK_CMD}}
if [ -z "$failed" ] && ! {{TYPECHECK_CMD}} >"$out" 2>&1; then failed="typecheck ({{TYPECHECK_CMD}})"; fi
{{/if}}

if [ -n "$failed" ]; then
  hook_log check_failed "$failed"
  {
    echo "harness: $failed failed on your changes. Fix it before finishing. Last lines:"
    tail -n 40 "$out"
  } >&2
  exit 2
fi
exit 0
