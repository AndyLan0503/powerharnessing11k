# shellcheck shell=bash
MODULE_DESC="CONTRIBUTING, CODEOWNERS, PR/issue templates (incl. agent task), SECURITY, agent handbook"

module_apply() {
  emit file CONTRIBUTING.md CONTRIBUTING.md
  emit seed SECURITY.md SECURITY.md
  emit file docs/HANDBOOK.md docs/agents/HANDBOOK.md
  emit file github/pull_request_template.md .github/pull_request_template.md
  emit file github/ISSUE_TEMPLATE/bug.yml .github/ISSUE_TEMPLATE/bug.yml
  emit file github/ISSUE_TEMPLATE/feature.yml .github/ISSUE_TEMPLATE/feature.yml
  emit file github/ISSUE_TEMPLATE/agent-task.yml .github/ISSUE_TEMPLATE/agent-task.yml
  if [ -n "$HV_CODEOWNERS" ]; then emit file github/CODEOWNERS .github/CODEOWNERS; fi
}
