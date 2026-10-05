# shellcheck shell=bash
MODULE_DESC="Local JSONL audit trail of agent tool use (.claude/logs/), summarised by .claude/scripts/agent-report.sh"

module_apply() {
  emit exec hooks/audit-log.sh .claude/hooks/audit-log.sh
  emit exec agent-report.sh .claude/scripts/agent-report.sh
  settings_hook PostToolUse "*" audit-log.sh 10
  settings_hook Stop "" audit-log.sh 10
}
