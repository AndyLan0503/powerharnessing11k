# shellcheck shell=bash
MODULE_DESC="CLAUDE.md / AGENTS.md, .claude/settings.json, cloud session-start hook, .gitignore"

module_apply() {
  emit block CLAUDE.md.tmpl CLAUDE.md
  if [ -n "$HV_MULTI_AGENT" ]; then emit block AGENTS.md.tmpl AGENTS.md; fi
  emit exec hooks/lib.sh .claude/hooks/lib.sh
  emit exec hooks/session-start.sh .claude/hooks/session-start.sh
  emit block gitignore.tmpl .gitignore
  emit seed editorconfig.tmpl .editorconfig
  emit seed permissions.tmpl .harness/permissions

  settings_hook SessionStart "" session-start.sh 600

  settings_allow 'Bash(git status:*)' 'Bash(git diff:*)' 'Bash(git log:*)' \
    'Bash(git show:*)' 'Bash(git branch:*)'
  local cmd
  for cmd in "$HV_LINT_CMD" "$HV_TYPECHECK_CMD" "$HV_TEST_CMD"; do
    [ -z "$cmd" ] || settings_allow "Bash($cmd:*)"
  done

  settings_deny 'Read(./.env)' 'Read(./.env.local)' 'Read(./.env.*.local)' \
    'Read(./.env.production)' 'Read(./secrets/**)' 'Read(./**/*.pem)' 'Read(./**/*.key)'
}
