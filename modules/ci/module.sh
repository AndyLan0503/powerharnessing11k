# shellcheck shell=bash
MODULE_DESC="GitHub Actions CI (install, lint, typecheck, test) and Conventional Commit PR titles"

module_apply() {
  emit file workflows/ci.yml .github/workflows/ci.yml
  emit file workflows/pr-title.yml .github/workflows/pr-title.yml
}
