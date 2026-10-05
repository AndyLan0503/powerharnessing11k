# shellcheck shell=bash
MODULE_DESC="Engineering skills (steward, task-intake) and the test-writer role"

module_apply() {
  emit_skill steward steward/SKILL.md
  emit_skill task-intake task-intake/SKILL.md
  emit_role test-writer agents/test-writer.md
}
