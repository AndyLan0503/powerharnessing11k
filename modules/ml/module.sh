# shellcheck shell=bash
MODULE_DESC="Data science & ML: experiment + data-audit skills, experiment log, dataset cards, immutable data/raw"

module_apply() {
  emit file skills/experiment.md .claude/skills/experiment/SKILL.md
  emit file skills/data-audit.md .claude/skills/data-audit/SKILL.md
  emit seed EXPERIMENTS.md EXPERIMENTS.md
  emit seed DATA.md docs/DATA.md
  emit seed data-readme.md data/README.md
}
