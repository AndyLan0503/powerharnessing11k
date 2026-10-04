# shellcheck shell=bash
MODULE_DESC="PreToolUse hooks that block destructive commands and edits to secrets/protected paths"

module_apply() {
  emit exec hooks/guard-bash.sh .claude/hooks/guard-bash.sh
  emit exec hooks/guard-paths.sh .claude/hooks/guard-paths.sh
  settings_hook PreToolUse Bash guard-bash.sh 10
  settings_hook PreToolUse 'Edit|MultiEdit|Write|NotebookEdit' guard-paths.sh 10
  settings_deny 'Bash(git push --force:*)' 'Bash(git push -f:*)'
  if [ -n "$HV_GUARD_STRICT" ]; then
    settings_ask 'Bash(git push:*)'
  fi
}
