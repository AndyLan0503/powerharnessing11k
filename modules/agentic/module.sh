# shellcheck shell=bash
MODULE_DESC="Agentic apps: prompt-change + agent-tool skills, prompts/ and evals/ layout, eval CI workflow"

module_apply() {
  emit file skills/prompt-change.md .claude/skills/prompt-change/SKILL.md
  emit file skills/agent-tool.md .claude/skills/agent-tool/SKILL.md
  emit seed prompts-readme.md prompts/README.md
  emit seed evals-readme.md evals/README.md
  emit seed example.jsonl evals/cases/example.jsonl
  if [ -n "$HV_EVAL_CMD" ]; then emit file evals.yml .github/workflows/evals.yml; fi
}
