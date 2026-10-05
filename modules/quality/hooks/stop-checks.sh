#!/usr/bin/env bash
# When the agent is about to finish and the working tree has changes, run the
# fast checks. On failure the output goes back to the agent so it fixes them.
# hook_stop_active guards against looping forever.
. "$(dirname "$0")/lib.sh"

hook_stop_active && exit 0
cd "$(hook_root)" || exit 0
[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0

out=$(mktemp)
trap 'rm -f "$out"' EXIT
failed=''
{{#if LINT_CMD}}
if ! { {{LINT_CMD}}; } >"$out" 2>&1; then failed=lint; fi
{{/if}}
{{#if TYPECHECK_CMD}}
if [ -z "$failed" ] && ! { {{TYPECHECK_CMD}}; } >"$out" 2>&1; then failed=typecheck; fi
{{/if}}

if [ -n "$failed" ]; then
  hook_log check_failed "$failed"
  hook_send_back "stop-checks: $failed failed on your changes. Fix it before finishing. Last lines:
$(tail -n 40 "$out")"
fi
exit 0
