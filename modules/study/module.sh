# shellcheck shell=bash
MODULE_DESC="Self-paced study: Learning output style, tutor/quiz/study-plan skills, plan + progress log, protected exercises/"

module_apply() {
  # The always-on profile rules (rules/profile.md) are included in AGENTS.md.
  emit_rule exercises rules/exercises.md
  emit_skill tutor skills/tutor.md
  emit_skill quiz skills/quiz.md
  emit_skill study-plan skills/study-plan.md
  emit seed LEARNING_PLAN.md LEARNING_PLAN.md
  emit seed PROGRESS.md PROGRESS.md
  emit seed notes-readme.md notes/README.md
  emit seed exercises-readme.md exercises/README.md
  # Claude Code's built-in style that pauses to have the learner write key parts.
  settings_agent claude string outputStyle Learning
}
