# shellcheck shell=bash
MODULE_DESC="Self-paced study: Learning output style, tutor/quiz/study-plan skills, plan + progress log, protected exercises/"

module_apply() {
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
