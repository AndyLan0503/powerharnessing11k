# shellcheck shell=bash
MODULE_DESC="Research: lab-notebook, lit-review, claim-check skills; research log, literature notes, references.bib"

module_apply() {
  # Always-on profile rules. With AGENTS.md they live there instead (shared with other agents).
  if [ -z "$HV_MULTI_AGENT" ]; then emit file rules/profile.md .claude/rules/research.md; fi
  emit file rules/literature.md .claude/rules/literature.md
  emit file agents/citation-verifier.md .claude/agents/citation-verifier.md
  emit file agents/devils-advocate.md .claude/agents/devils-advocate.md
  emit file skills/lab-notebook.md .claude/skills/lab-notebook/SKILL.md
  emit file skills/lit-review.md .claude/skills/lit-review/SKILL.md
  emit file skills/claim-check.md .claude/skills/claim-check/SKILL.md
  emit seed RESEARCH_LOG.md RESEARCH_LOG.md
  emit seed references.bib references.bib
  emit seed literature-readme.md literature/README.md
  # Finding and checking sources is core research work.
  settings_allow WebSearch
}
