# shellcheck shell=bash
MODULE_DESC="Hooks that block destructive commands and edits to secrets/protected paths"

module_apply() {
  emit_hook hooks/guard-bash.sh
  emit_hook hooks/guard-paths.sh
  settings_hook pre-shell guard-bash.sh 10
  settings_hook pre-edit guard-paths.sh 10
  settings_deny_cmd 'git push --force' 'git push -f'
  if [ -n "$HV_GUARD_STRICT" ]; then
    settings_ask_cmd 'git push'
  fi
}
