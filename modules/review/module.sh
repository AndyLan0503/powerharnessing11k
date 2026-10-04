# shellcheck shell=bash
MODULE_DESC="Claude Code GitHub Action: @claude on issues/PRs and automatic PR review (needs ANTHROPIC_API_KEY)"

module_apply() {
  emit file github/claude.yml .github/workflows/claude.yml
  emit file github/claude-review.yml .github/workflows/claude-review.yml
  emit block REVIEW.md REVIEW.md
}
