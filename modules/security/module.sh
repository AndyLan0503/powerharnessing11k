# shellcheck shell=bash
MODULE_DESC="Dependabot (deps + actions), CodeQL code scanning, dependency review on PRs"

module_apply() {
  emit file github/dependabot.yml .github/dependabot.yml
  emit file github/codeql.yml .github/workflows/codeql.yml
  emit file github/dependency-review.yml .github/workflows/dependency-review.yml
}
