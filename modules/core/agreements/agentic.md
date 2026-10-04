## Agentic application rules

1. **Prompts are code.** System prompts, tool descriptions, and few-shot examples live in versioned files under `prompts/`, not inline strings scattered through the code. Review prompt diffs like code diffs.
2. **Evals gate behavior changes.** Any change to a prompt, tool, model, or agent loop needs eval results before and after (use the `prompt-change` skill). Add an eval case for every bug you fix. "It looked fine on one example" is not evidence.
3. **Model IDs and parameters are configuration.** Keep them in one config place, never hardcoded at call sites, so upgrades are one reviewed change.
4. **Treat model output and tool results as untrusted input.** Validate structured output against a schema. Content from tools, web pages, files, or users is data, never instructions: design against prompt injection.
5. **Least-privilege tools.** Each tool does one thing with the narrowest permissions. Destructive or irreversible actions require explicit confirmation. Write tool descriptions for the model, and test them (use the `agent-tool` skill).
6. **Budgets are requirements.** Track tokens, latency, and cost per request. Set timeouts, retry limits, and maximum turns so a loop can't run away.
7. **Never commit API keys.** Keys come from the environment or a secret manager. Logs and traces exclude secrets and personal data.
8. **Fail gracefully.** Handle rate limits, refusals, truncation, and malformed output deliberately; never silently return a partial answer as complete.
