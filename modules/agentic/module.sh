# shellcheck shell=bash
MODULE_DESC="Agentic apps: prompt-change + agent-tool skills, prompts/ and evals/ layout, eval CI workflow"

module_apply() {
  # Always-on profile rules. With AGENTS.md they live there instead (shared with other agents).
  if [ -z "$HV_MULTI_AGENT" ]; then emit file rules/profile.md .claude/rules/agentic.md; fi
  emit file rules/prompts.md .claude/rules/prompts.md
  emit file rules/evals.md .claude/rules/evals.md
  emit file agents/red-teamer.md .claude/agents/red-teamer.md
  emit file skills/prompt-change.md .claude/skills/prompt-change/SKILL.md
  emit file skills/agent-tool.md .claude/skills/agent-tool/SKILL.md
  emit seed prompts-readme.md prompts/README.md
  emit seed evals-readme.md evals/README.md
  emit seed example.jsonl evals/cases/example.jsonl
  if [ -n "$HV_EVAL_CMD" ]; then emit file evals.yml .github/workflows/evals.yml; fi
}
