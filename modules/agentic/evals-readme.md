# evals/

Evaluation cases that gate changes to prompts, tools, models, and agent logic.

- `cases/*.jsonl`: one case per line. Start from `cases/example.jsonl`.
- `results/`: local run outputs (git-ignored).
{{#if EVAL_CMD}}
- Run: `{{EVAL_CMD}}`. CI runs it on PRs that touch prompts, evals, or agent code (`.github/workflows/evals.yml`).
{{/if}}
{{#unless EVAL_CMD}}
- TODO(team): no eval command configured yet. Add one here and a CI workflow that runs it on PRs touching prompts, evals, or agent code.
{{/if}}

Good eval sets cover: the main tasks, every bug ever fixed (a regression case each), adversarial inputs (prompt injection, jailbreak attempts, malformed data), and cases where the agent should refuse, ask, or *not* call a tool.

Grade with exact or programmatic checks where possible. When using an LLM as a judge, version the judge prompt in `prompts/` and spot-check its verdicts.
