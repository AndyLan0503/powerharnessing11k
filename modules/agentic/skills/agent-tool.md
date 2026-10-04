---
name: agent-tool
description: Design, implement, and test a tool that an LLM agent in {{PROJECT_NAME}} can call. Use when adding or changing a tool, function-calling schema, or MCP server.
---

# Adding a tool for the agent

1. **One job, least privilege.** The tool does one thing. Give it the narrowest scope possible: read-only if it can be, limited to specific resources, and with no ambient credentials.
2. **Schema.** Strict JSON schema: required fields, enums instead of free text where possible, sensible bounds. Validate inputs server-side anyway.
3. **Description for the model.** Say when to use it, when *not* to, what it returns, and one example. The description is a prompt: version it in `prompts/` if it lives outside code, and eval it.
4. **Dangerous actions.** Anything destructive, irreversible, external-facing, or costly requires explicit confirmation (human-in-the-loop) or a dry-run mode.
5. **Untrusted output.** Tool results may contain injected instructions (web pages, emails, files). Return them as clearly delimited data, and never let them change system behavior.
6. **Errors.** Return structured, actionable errors the model can recover from ("field X must be a date, got Y"). Set timeouts.
7. **Tests.** Unit-test the tool itself, then add eval cases in `evals/cases/` where the agent should and should not call it.
8. **Observability.** Log the call, its arguments (without secrets or personal data), duration, and outcome.
