# shellcheck shell=bash
MODULE_DESC="AI review in the PR gate (claude -p, JSON-schema findings, per-file + cross-file passes), @claude mentions, REVIEW.md (needs ANTHROPIC_API_KEY)"

module_apply() {
  emit exec github/ai-review.sh .github/scripts/ai-review.sh
  emit file github/findings.schema.json .github/review/findings.schema.json
  emit seed github/criteria.md .github/review/criteria.md
  emit file github/claude.yml .github/workflows/claude.yml
  emit block REVIEW.md REVIEW.md
  # The gate workflow normally comes with agent-guard; provide it if that's off.
  if [ -z "$HV_MOD_AGENT_GUARD" ]; then
    emit exec ../agent-guard/github/pr-gate.sh .github/scripts/pr-gate.sh
    emit file ../agent-guard/github/pr-gate.yml .github/workflows/pr-gate.yml
  fi
}
