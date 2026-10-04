# shellcheck shell=bash
MODULE_DESC="CI monitoring of agent PRs: auto-label, flag deleted/skipped tests, protected paths, size; weekly digest"

module_apply() {
  emit exec github/agent-guard.sh .github/scripts/agent-guard.sh
  emit file github/agent-guard.yml .github/workflows/agent-guard.yml
  emit file github/agent-digest.yml .github/workflows/agent-digest.yml
}
