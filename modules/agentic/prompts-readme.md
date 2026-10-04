# prompts/

System prompts, tool descriptions, and few-shot examples live here as plain files (Markdown or text) and are loaded by the application, not inlined in code.

- One file per prompt, named for its role, e.g. `support-agent.system.md`, `search.tool.md`.
- Changes go through the `prompt-change` skill: evals before and after, results in the PR.
- Keep model IDs and sampling parameters in application config, not here.
