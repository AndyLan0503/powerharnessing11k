# shellcheck shell=bash
MODULE_DESC="Repo skills (steward, task-intake) and subagents (reviewer, test-writer)"

module_apply() {
  emit file steward/SKILL.md .claude/skills/steward/SKILL.md
  emit file task-intake/SKILL.md .claude/skills/task-intake/SKILL.md
  emit file agents/reviewer.md .claude/agents/reviewer.md
  emit file agents/test-writer.md .claude/agents/test-writer.md
}
