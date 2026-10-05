# shellcheck shell=bash
MODULE_DESC="Research: lab-notebook, lit-review, claim-check skills; research log, literature notes, references.bib"

module_apply() {
  # The always-on profile rules (rules/profile.md) are included in AGENTS.md.
  emit_rule literature rules/literature.md
  emit_skill lab-notebook skills/lab-notebook.md
  emit_skill lit-review skills/lit-review.md
  emit_skill claim-check skills/claim-check.md
  emit seed RESEARCH_LOG.md RESEARCH_LOG.md
  emit seed references.bib references.bib
  emit seed literature-readme.md literature/README.md
  # Finding and checking sources is core research work.
  settings_allow_tool websearch
}
