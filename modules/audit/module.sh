# shellcheck shell=bash
MODULE_DESC="Local JSONL audit trail of agent tool use (.harness/logs/), summarised by .harness/report.sh"

module_apply() {
  emit exec hooks/audit-log.sh .claude/hooks/audit-log.sh
  emit exec report.sh .harness/report.sh
  settings_hook PostToolUse "*" audit-log.sh 10
  settings_hook Stop "" audit-log.sh 10
}
