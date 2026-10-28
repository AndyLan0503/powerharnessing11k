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

out=$(mktemp) changed=$(mktemp) others=$(mktemp)
trap 'rm -f "$out" "$changed" "$others"' EXIT
# Names of the files this work touched (changed, added, or new), and of every
# other tracked file. Names, not paths: tools print paths relative to where
# they run, which in a monorepo is not the repo root.
git status --porcelain --untracked-files=all 2>/dev/null | cut -c4- |
  sed 's/.* -> //; s/^"//; s/"$//; s|.*/||; /^$/d' | sort -u >"$changed"
git ls-files 2>/dev/null | sed 's|.*/||; /^$/d' | sort -u | comm -23 - "$changed" >"$others"

# blame CHECK: a failure goes back to the agent when its output names a file
# the agent touched, or names no file at all (a config error, a crash). One
# that names only other files was there before: the agent is not pulled into
# fixing code it never touched, and the failure is logged for the team.
report=''
blame() {
  if ! grep -qF -f "$changed" "$out" && grep -qF -f "$others" "$out"; then
    hook_log check_failed_elsewhere "$1"
    return
  fi
  hook_log check_failed "$1"
  report="${report:+$report

}$1 failed on your changes. Last lines:
$(tail -n 40 "$out")"
}
{{#if LINT_CMD}}
if ! { {{LINT_CMD}}; } >"$out" 2>&1; then blame lint; fi
{{/if}}
{{#if TYPECHECK_CMD}}
if ! { {{TYPECHECK_CMD}}; } >"$out" 2>&1; then blame typecheck; fi
{{/if}}

[ -z "$report" ] || hook_send_back "stop-checks: fix these before finishing.
$report"
exit 0
