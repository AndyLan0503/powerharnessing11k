# shellcheck shell=bash
MODULE_DESC="AGENTS.md (project context, working agreement), path-scoped rules, permissions, review + handoff skills, reviewer role, session-start hook"

module_apply() {
  # AGENTS.md, the source of truth for every agent, is written by
  # agents_md_emit (lib/agents.sh) once all modules have run.
  emit_hook hooks/lib.sh
  emit_hook hooks/session-start.sh
  emit append gitignore.tmpl .gitignore
  emit file editorconfig.tmpl .editorconfig

  # Shared skills and the shared reviewer role (not for solo study repos).
  emit_skill handoff skills/handoff.md
  if [ -z "$HV_PROFILE_STUDY" ]; then
    emit_skill review skills/review.md
    emit_role reviewer agents/reviewer.md
  fi

  # Path-scoped rules: loaded only when the agent works on matching files.
  if [ -n "$HV_PROFILE_ENGINEERING" ]; then
    emit_rule testing rules/testing.md
    emit_rule github-actions rules/github-actions.md
  fi
  if [ -n "$HV_PROTECT_RAW_DATA" ]; then emit_rule data rules/data.md; fi
  if [ -n "$HV_NOTEBOOK_CHECK" ]; then emit_rule notebooks rules/notebooks.md; fi

  settings_hook session-start session-start.sh 600
  settings_allow_cmd 'git status' 'git diff' 'git log' 'git show' 'git branch'
  local cmd
  for cmd in "$HV_LINT_CMD" "$HV_TYPECHECK_CMD" "$HV_TEST_CMD"; do
    [ -z "$cmd" ] || settings_allow_cmd "$cmd"
  done
  settings_deny_read '.env' '.env.local' '.env.*.local' '.env.production' \
    'secrets/**' '**/*.pem' '**/*.key'
}
