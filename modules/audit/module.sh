# shellcheck shell=bash
MODULE_DESC="Local JSONL audit trail of agent tool use (.agents/logs/), summarised by .agents/scripts/agent-report.sh"

module_apply() {
  emit_hook hooks/audit-log.sh
  emit exec agent-report.sh .agents/scripts/agent-report.sh
  settings_hook post-tool audit-log.sh 10
  settings_hook stop audit-log.sh 10
}
