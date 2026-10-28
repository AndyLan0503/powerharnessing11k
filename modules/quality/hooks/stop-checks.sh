#!/usr/bin/env bash
# When the agent is about to finish and the working tree has changes, run the
# fast checks. On failure the output goes back to the agent so it fixes them.
# hook_stop_active guards against looping forever.
. "$(dirname "$0")/lib.sh"

hook_stop_active && exit 0
cd "$(hook_root)" || exit 0
[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0
{{#if STACK_MANIFESTS}}
# Until the project itself exists ({{STACK_MANIFESTS}}), there is nothing
# for lint or typecheck to run against: skip instead of failing every turn.
found=''
for m in {{STACK_MANIFESTS}}; do [ ! -e "$m" ] || found=1; done
[ -n "$found" ] || exit 0
{{/if}}

out=$(mktemp)
trap 'rm -f "$out"' EXIT
# Every check runs, so one failure cannot hide another.
report=''
failed() { # CHECK: add its output to the report
  hook_log check_failed "$1"
  report="${report:+$report

}$1 failed. Last lines:
$(tail -n 40 "$out")"
}
{{#if LINT_CMD}}
if ! { {{LINT_CMD}}; } >"$out" 2>&1; then failed lint; fi
{{/if}}
{{#if TYPECHECK_CMD}}
if ! { {{TYPECHECK_CMD}}; } >"$out" 2>&1; then failed typecheck; fi
{{/if}}

# A hook cannot tell which failures this change caused: changing a function
# breaks its callers, in files the change never touched. The agent can, so
# it decides, within the scope of its task.
[ -z "$report" ] || hook_send_back "stop-checks: fix what your change caused before finishing, including breakage in code that calls what you changed.
If a failure was already there before your change, do not fix it as part of this task: say so in your reply, so it can be fixed separately.

$report"
exit 0
