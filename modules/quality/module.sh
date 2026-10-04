# shellcheck shell=bash
MODULE_DESC="Format files after agent edits; run lint/typecheck before the agent finishes"

module_apply() {
  if [ -n "$HV_FORMAT_CMD" ]; then
    emit exec hooks/format-on-edit.sh .claude/hooks/format-on-edit.sh
    settings_hook PostToolUse 'Edit|MultiEdit|Write' format-on-edit.sh 60
  fi
  if [ -n "$HV_LINT_CMD$HV_TYPECHECK_CMD" ] && [ "$HV_GUARD_LEVEL" != relaxed ]; then
    emit exec hooks/stop-checks.sh .claude/hooks/stop-checks.sh
    settings_hook Stop "" stop-checks.sh 600
  fi
}
