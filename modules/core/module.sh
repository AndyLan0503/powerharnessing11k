# shellcheck shell=bash
MODULE_DESC="CLAUDE.md / AGENTS.md, .claude/rules, settings.json, /review + /handoff commands, reviewer role, session-start hook"

module_apply() {
  emit file CLAUDE.md.tmpl CLAUDE.md
  if [ -n "$HV_MULTI_AGENT" ]; then emit file AGENTS.md.tmpl AGENTS.md; fi
  emit exec hooks/lib.sh .claude/hooks/lib.sh
  emit exec hooks/session-start.sh .claude/hooks/session-start.sh
  emit append gitignore.tmpl .gitignore
  emit file editorconfig.tmpl .editorconfig

  # Shared commands and the shared reviewer role (not for solo study repos).
  emit file commands/handoff.md .claude/commands/handoff.md
  if [ -z "$HV_PROFILE_STUDY" ]; then
    emit file commands/review.md .claude/commands/review.md
    emit file agents/reviewer.md .claude/agents/reviewer.md
  fi

  # Path-scoped rules: loaded only when Claude works on matching files.
  if [ -n "$HV_PROFILE_ENGINEERING" ]; then
    emit file rules/testing.md .claude/rules/testing.md
    emit file rules/github-actions.md .claude/rules/github-actions.md
  fi
  if [ -n "$HV_PROTECT_RAW_DATA" ]; then emit file rules/data.md .claude/rules/data.md; fi
  if [ -n "$HV_NOTEBOOK_CHECK" ]; then emit file rules/notebooks.md .claude/rules/notebooks.md; fi

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
