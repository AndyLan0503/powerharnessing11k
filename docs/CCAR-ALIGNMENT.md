# CCAR alignment

How harness applies the practices in the Claude Certified Architect exam guides: **CCAR-F** (Foundations, v1.0, July 2026) and **CCAR-P** (Professional, v1.0, July 2026). Only task statements that a repository harness can put into practice are listed. Topics that belong in application code (the Batch API, RAG design, compliance programs) are noted at the end.

## CCAR-F

| Task statement | Practice | Where in harness |
|---|---|---|
| **1.4** Programmatic enforcement vs prompt guidance | Rules that must always hold are hooks and CI gates; `CLAUDE.md` only guides | `guard-bash.sh`, `guard-paths.sh`, `stop-checks.sh`, PR gate; "Hooks enforce; this file guides" in `CLAUDE.md` |
| **1.5** Hooks that intercept tool calls | PreToolUse hooks block policy-violating commands and edits, and explain why to the agent | `modules/guardrails/hooks/` |
| **1.2 / 1.3** Subagents get explicit context; coordinators route | Roles are separate subagents with their own instructions; `/review` passes the base ref and intent explicitly | `.claude/agents/*`, `.claude/commands/review.md` |
| **1.7** Fresh session with a summary vs resuming stale context | `/handoff` writes a structured summary; the guidance prefers it over resuming with stale tool results | `.claude/commands/handoff.md`, "How we work" |
| **2.1** Tool descriptions as the selection mechanism | Agentic profile rules and the `agent-tool` skill; `prompts.md` path rule | `modules/agentic/` |
| **2.2 / 5.3** Structured errors, retryable vs not, empty vs failed | Agentic profile rule 6 | `.claude/rules/agentic.md` |
| **2.3** Scoped tool access per agent (4–5 tools) | The shared roles declare minimal `tools:` lists; skills restrict `allowed-tools`. Harness ships only the two near-universal roles (`reviewer`, `test-writer`); teams add domain roles in their own repos | `.claude/agents/*`, skill frontmatter |
| **2.4** MCP in project `.mcp.json` with `${ENV}` expansion; personal servers in user scope | `mcp` module (strict tiers) | `.mcp.json`, `docs/agents/MCP.md` |
| **2.5** Built-in tools used incrementally | "Grep for entry points, then Read along the flow" | "How we work" |
| **3.1** CLAUDE.md hierarchy and modular rules | Project `CLAUDE.md` (shared through git) plus `.claude/rules/` topic files; `AGENTS.md` import for multi-agent repos | `modules/core/` |
| **3.2** Project commands and skills; `context: fork`, `allowed-tools`, `argument-hint` | `/review`, `/handoff`; every skill has `argument-hint`; read-heavy skills (`data-audit`, `claim-check`) run forked with read-only tools | `.claude/commands/`, `.claude/skills/` |
| **3.3** Path-specific rules with `paths:` globs | `testing.md` (test files anywhere), `github-actions.md`, `data.md`, `notebooks.md`, `prompts.md`, `evals.md`, `exercises.md`, `literature.md` | `.claude/rules/` |
| **3.4** Plan mode vs direct execution; Explore subagent | "Plan before big changes", "Explore without flooding the context" | "How we work" |
| **3.5** Concrete examples, test-driven iteration, interview pattern | "Interview before building", "Show, then test" | "How we work", `task-intake` |
| **3.6** Claude Code in CI: `-p`, `--output-format json`, `--json-schema`, `CLAUDE.md` as CI context, independent review, prior findings to avoid duplicates | `ai-review.sh` runs `claude -p` with a findings JSON schema and read-only tools, in a fresh instance; earlier findings are fingerprinted, passed back in, and never reposted | `.github/scripts/ai-review.sh`, `.github/review/` |
| **4.1** Explicit criteria; disable high-false-positive categories | `criteria.md` lists categories to report and to skip, each with an on/off status, plus severity definitions with code examples | `.github/review/criteria.md` |
| **4.2** Few-shot examples for format and ambiguous cases | Report / don't-report / nit examples in the criteria | `.github/review/criteria.md` |
| **4.3** Structured output via schemas | Strict findings schema with enums and nullable fields | `.github/review/findings.schema.json` |
| **4.4** `detected_pattern` for dismissal analysis | Every finding has a `detected_pattern`; the weekly digest counts 👎 dismissals per pattern | `ai-review.sh`, `pr-digest.yml` |
| **4.5** Batch API only for latency-tolerant work | The blocking pre-merge review is synchronous; agentic rules reserve batch for overnight jobs | `.claude/rules/agentic.md` |
| **4.6** Independent instances; per-file plus cross-file passes; confidence for routing | One pass per file, then one cross-file pass; low-confidence findings go to "needs a human look" instead of inline comments | `ai-review.sh` |
| **5.1 / 5.4** Context management: scratchpads, `/compact`, subagent delegation | "Long sessions" guidance; Explore delegation; `/handoff` | "How we work" |
| **5.2** Escalation criteria, not sentiment or self-confidence | Agentic rule 12 | `.claude/rules/agentic.md` |
| **5.5** Segment-level accuracy; calibrated confidence before automating | ML rules 5 and 8; `evals.md` path rule | `.claude/rules/ml.md`, `evals.md` |
| **5.6** Provenance: claim→source mappings, conflicts annotated, dates | Research rules 2–4; `lit-review`; `claim-check` | `modules/research/` |

## CCAR-P

| Domain / objective | Practice | Where in harness |
|---|---|---|
| **2** Prompt reuse (caching, modular prompts, Skills) | Static content first for caching; prompts as versioned files; skills for reusable workflows | agentic rules, `prompts.md` |
| **3** Capability bloat; least privilege; auth gaps | Least-privilege tools and roles; deny rules for secrets; scoped MCP credentials | agentic rule 5, `settings.json`, `.mcp.json` |
| **3** Observability at scale | OpenTelemetry export, local audit log, PR scorecards, weekly digest | `telemetry`, `audit`, PR gate |
| **4** Metrics (accuracy, latency, cost, safety); eval datasets; A/B; diagnosis | Evals gate behavior changes, reported by segment; `prompt-change` compares before and after; the eval workflow runs on relevant PRs | `modules/agentic/`, `evals.yml` |
| **5** Guardrails and safety controls | Guard levels, path protection, PR gate | `guardrails`, `diff-guard` |
| **5** Human-in-the-loop validation | A human approves every merge; `gate-override` is an explicit, recorded human risk acceptance; low-confidence findings go to humans | PR gate, `HANDBOOK.md` |
| **6** Document decisions and trade-offs; lifecycle support | Handbook, ADRs (this repo), scorecards and digest for monitoring and iteration | `docs/`, `pr-digest.yml` |
| **7** Configure Claude tools for teams; improve developer workflows | All of harness | n/a |

## Not covered (application-level topics)

The Agent SDK loop internals (`stop_reason` handling, `fork_session`, `tool_choice`), the Batch API, RAG chunking and indexing, compliance programs (GDPR, HIPAA, FedRAMP), and stakeholder discovery are design concerns of the application being built. The agentic profile *guides* agents on the first three. Harness doesn't implement them.
