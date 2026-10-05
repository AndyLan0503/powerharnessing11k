# shellcheck shell=bash
MODULE_DESC="Agentic apps: prompt-change + agent-tool skills, prompts/ and evals/ layout, eval CI workflow"

module_apply() {
  # The always-on profile rules (rules/profile.md) are included in AGENTS.md.
  emit_rule prompts rules/prompts.md
  emit_rule evals rules/evals.md
  emit_skill prompt-change skills/prompt-change.md
  emit_skill agent-tool skills/agent-tool.md
  emit seed prompts-readme.md prompts/README.md
  emit seed evals-readme.md evals/README.md
  emit seed example.jsonl evals/cases/example.jsonl
  if [ -n "$HV_EVAL_CMD" ]; then emit file evals.yml .github/workflows/evals.yml; fi
}
