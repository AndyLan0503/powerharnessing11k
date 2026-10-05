# shellcheck shell=bash
MODULE_DESC="AI review in the PR gate (claude -p, JSON-schema findings, per-file + cross-file passes), @claude mentions, REVIEW.md (needs ANTHROPIC_API_KEY)"

module_apply() {
  emit exec ci/ai-review.sh scripts/ci/ai-review.sh
  emit file ci/findings.schema.json scripts/ci/review/findings.schema.json
  emit seed ci/criteria.md scripts/ci/review/criteria.md
  emit file github/claude.yml .github/workflows/claude.yml
  emit file REVIEW.md REVIEW.md
  # The gate workflow normally comes with diff-guard; provide it if that's off.
  if [ -z "$HV_MOD_DIFF_GUARD" ]; then
    emit exec ../diff-guard/ci/pr-gate.sh scripts/ci/pr-gate.sh
    emit file ../diff-guard/github/pr-gate.yml .github/workflows/pr-gate.yml
  fi
}
