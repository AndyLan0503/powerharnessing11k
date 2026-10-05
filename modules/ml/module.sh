# shellcheck shell=bash
MODULE_DESC="Data science & ML: experiment + data-audit skills, experiment log, dataset cards, immutable data/raw"

module_apply() {
  # The always-on profile rules (rules/profile.md) are included in AGENTS.md.
  emit_skill experiment skills/experiment.md
  emit_skill data-audit skills/data-audit.md
  emit seed EXPERIMENTS.md EXPERIMENTS.md
  emit seed DATA.md docs/DATA.md
  emit append gitignore.tmpl .gitignore
}
