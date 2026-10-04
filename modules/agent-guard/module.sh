# shellcheck shell=bash
MODULE_DESC="PR gate: detect + label agent PRs, flag risky diffs (deleted/skipped tests, protected paths, size), scorecard; weekly digest"

module_apply() {
  emit exec github/agent-guard.sh .github/scripts/agent-guard.sh
  emit exec github/pr-gate.sh .github/scripts/pr-gate.sh
  emit file github/pr-gate.yml .github/workflows/pr-gate.yml
  emit file github/agent-digest.yml .github/workflows/agent-digest.yml
}
