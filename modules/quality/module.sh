# shellcheck shell=bash
MODULE_DESC="Format files after agent edits; run lint/typecheck before the agent finishes"

module_apply() {
  if [ -n "$HV_FORMAT_CMD" ]; then
    emit_hook hooks/format-on-edit.sh
    settings_hook post-edit format-on-edit.sh 60
  fi
  if [ -n "$HV_LINT_CMD$HV_TYPECHECK_CMD" ] && [ "$HV_GUARD_LEVEL" != relaxed ]; then
    emit_hook hooks/stop-checks.sh
    settings_hook stop stop-checks.sh 600
  fi
}
