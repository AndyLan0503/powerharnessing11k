# shellcheck shell=bash
MODULE_DESC="PR gate for every PR: flag risky diffs (deleted/skipped tests, protected paths, size), scorecard, human override; weekly digest"

module_apply() {
  emit exec github/diff-guard.sh .github/scripts/diff-guard.sh
  emit exec github/pr-gate.sh .github/scripts/pr-gate.sh
  emit file github/pr-gate.yml .github/workflows/pr-gate.yml
  emit file github/pr-digest.yml .github/workflows/pr-digest.yml
}
