# shellcheck shell=bash
MODULE_DESC="Engineering skills (steward, task-intake) and the test-writer role"

module_apply() {
  emit file steward/SKILL.md .claude/skills/steward/SKILL.md
  emit file task-intake/SKILL.md .claude/skills/task-intake/SKILL.md
  emit file agents/test-writer.md .claude/agents/test-writer.md
}
