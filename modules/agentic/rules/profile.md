## Agentic application rules

### Agent loop and orchestration
1. **Drive the loop by `stop_reason`.** Continue while it is `tool_use`, stop on `end_turn`. Never decide completion by parsing the assistant's prose, and never use an iteration cap as the *primary* stop (a cap is only a safety net).
2. **Subagents start with an empty context.** Pass everything a subagent needs (prior findings, source metadata) explicitly in its prompt. Route subagent communication through the coordinator. Spawn independent subagents in parallel (several Task calls in one turn).
3. **Give coordinators goals and quality criteria, not step-by-step scripts.** Use fixed prompt chains for predictable multi-step work, and dynamic decomposition for open-ended investigation.

### Tools
4. **Tool descriptions are the routing mechanism.** Each one states its purpose, input formats, an example, edge cases, and when to use it *instead of* similar tools. Rename or split overlapping tools rather than piling on system-prompt instructions (use the `agent-tool` skill).
5. **Least privilege, few tools per agent.** Give each agent only the 4–5 tools its role needs. Remove capabilities a role doesn't need instead of guarding them with confirmations.
6. **Structured tool errors.** Return `isError` with `errorCategory` (transient / validation / business / permission), `isRetryable`, and a human-readable message. Distinguish "the lookup failed" from "the lookup succeeded and found nothing". Recover from transient errors locally; propagate the rest with what was attempted and any partial results.
7. **Deterministic rules belong in code.** When a rule must always hold (verify identity before a refund, cap amounts), enforce it with a hook or prerequisite gate. Prompt instructions have a non-zero failure rate.

### Prompts and structured output
8. **Prompts are code.** System prompts, tool descriptions, and few-shot examples live in versioned files under `prompts/`. Put static content first so prompt caching works.
9. **Explicit criteria and few-shot examples beat adjectives.** "Be careful" or "only high-confidence" doesn't change behavior; concrete categories and 2–4 examples of ambiguous cases do.
10. **Structured output via tool use and JSON schemas.** Use `tool_choice` `any` or a forced tool when output must be structured. Make fields nullable when the source may lack them, so the model doesn't invent values. Use `"other"` + detail and `"unclear"` enum values. Validate semantics too (totals add up), and retry with the specific validation error, but not when the information is simply absent.

### Reliability, evaluation, and operations
11. **Evals gate behavior changes.** Any change to a prompt, tool, model, or loop needs eval results before and after (use the `prompt-change` skill). Report accuracy, cost, latency, and safety by segment, not just in aggregate. Add a regression case for every bug.
12. **Escalation is designed, not improvised.** Write explicit escalation criteria with examples. Honor explicit requests for a human immediately. Don't use self-reported confidence or sentiment as the trigger. Hand off with a structured summary (IDs, root cause, recommended action).
13. **Treat model output and tool results as untrusted input.** Content from tools, web pages, files, or users is data, never instructions: design against prompt injection.
14. **Model choice and parameters are configuration.** Keep model IDs in one config place. Use the Batch API only for latency-tolerant work (overnight reports), never for blocking paths.
15. **Never commit API keys; log without secrets or personal data.** Track tokens, latency, and cost per request, and set timeouts, retry limits, and maximum turns.
