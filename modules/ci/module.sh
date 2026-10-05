# shellcheck shell=bash
MODULE_DESC="GitHub Actions CI (install, lint, typecheck, fast tests; nightly full tests) and Conventional Commit PR titles"

module_apply() {
  emit file workflows/ci.yml .github/workflows/ci.yml
  emit file workflows/pr-title.yml .github/workflows/pr-title.yml
  if [ -n "${HV_FULL_TEST_CMD:-}" ]; then
    emit file workflows/tests-full.yml .github/workflows/tests-full.yml
  fi
}
