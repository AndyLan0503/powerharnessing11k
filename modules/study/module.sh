# shellcheck shell=bash
MODULE_DESC="Self-paced study: Learning output style, tutor/quiz/study-plan skills, plan + progress log, protected exercises/"

module_apply() {
  # Always-on profile rules. With AGENTS.md they live there instead (shared with other agents).
  if [ -z "$HV_MULTI_AGENT" ]; then emit file rules/profile.md .claude/rules/study.md; fi
  emit file rules/exercises.md .claude/rules/exercises.md
  emit file skills/tutor.md .claude/skills/tutor/SKILL.md
  emit file skills/quiz.md .claude/skills/quiz/SKILL.md
  emit file skills/study-plan.md .claude/skills/study-plan/SKILL.md
  emit seed LEARNING_PLAN.md LEARNING_PLAN.md
  emit seed PROGRESS.md PROGRESS.md
  emit seed notes-readme.md notes/README.md
  emit seed exercises-readme.md exercises/README.md
  # Claude Code's built-in style that pauses to have the learner write key parts.
  settings_string outputStyle Learning
}
