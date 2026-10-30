# Working with coding agents in {{PROJECT_NAME}}

This handbook is the team's policy for agentic work. It belongs to the team: change it through a PR like any other file.

## Principles

1. **Agents are teammates with limits.** Agent changes follow the same PR and review path{{#if MOD_CI}}, and the same CI,{{/if}} as human changes, plus extra checks and an audit trail.
2. **A human owns every agent change.** Whoever launches an agent owns its output: reviewing it, merging it, and answering for it.
3. **Context lives in the repo.** `AGENTS.md`, skills, and this handbook are versioned and reviewed like code. If an agent keeps making the same mistake, fix the context, not just the PR.
4. **Guardrails are mechanical.** Hooks and permissions{{#if MOD_CI}}, plus required CI checks,{{/if}} enforce the rules; this document explains them.

## When to use an agent

Good fits: well-specified bugs, test backfills, mechanical refactors, migrations with a clear pattern, docs, scaffolding, CI fixes.

Poor fits: ambiguous product decisions, security-sensitive code without an expert reviewer, changes with no way to verify them, sweeping multi-module redesigns.

## Writing a good agent task

- Use the **Agent task** issue template.
- State the goal and **testable** acceptance criteria.
- Point to the relevant files and prior art.
- Say what is out of scope.
- If it would be more than ~400 lines, split it.

## Reviewing PRs

Every PR gets the same {{#if MOD_DIFF_GUARD}}gate and the same {{/if}}review, whoever or whatever wrote it. Nobody is asked to declare how a change was produced. Look closely at:

- **Tests:** were any deleted, skipped, or weakened?{{#if MOD_DIFF_GUARD}} The diff-guard check flags this.{{/if}}
- **Scope:** does the diff stay within the task?
- **Dependencies:** any new packages? Are they justified and maintained?
- **Confident-sounding claims:** verify "I ran the tests" against {{#if MOD_CI}}CI{{/if}}{{#unless MOD_CI}}a run of your own{{/if}}.

## What each coding agent gets

Project context (`AGENTS.md`), skills (`.agents/skills/`), and the guard hooks (`.agents/hooks/`) are shared by every agent set up here. The rest depends on what each agent supports:

| Agent | Path-scoped rules | Subagent limits | Command permissions | Before finishing |
|---|---|---|---|---|
{{AGENT_COVERAGE}}

Other agents that read `AGENTS.md` still get the project context and working agreement, without the hooks.
{{#if MOD_CI}}
CI applies to every change, whichever tool wrote it.
{{/if}}
{{#if MOD_DIFF_GUARD}}
So does the PR gate.
{{/if}}

## Guardrails at a glance (level: {{GUARD_LEVEL}})

| Layer | What it does |
|---|---|
| Permissions (each agent's settings file) | Pre-approve safe commands; deny reading secrets |
| Hooks (`.agents/hooks/`) | Block force-push, `--no-verify`, destructive deletes, secret edits{{#if GUARD_STRICT}}, CI/guardrail edits{{/if}} |
{{#if MOD_CI}}
| CI (`ci.yml`) | Lint, typecheck, and tests are required to merge |
{{/if}}
{{#if MOD_DIFF_GUARD}}
| PR gate (`pr-gate.yml`) | One required check for every PR. Flags test deletion, skipped tests, protected paths, oversized diffs, and new dependencies; posts a scorecard; `gate-override` records a human's risk acceptance |
| Weekly digest (`pr-digest.yml`) | PR volume, merge rate, reverts, gate scores and findings, and AI-review false-positive rates by pattern |
{{/if}}
{{#if MOD_REVIEW}}
| AI review (in the PR gate) | An independent Claude Code instance reviews each file, then the change as a whole, against `scripts/ci/review/criteria.md`; blocking findings fail the gate. React 👎 on false positives |
{{/if}}
{{#if MOD_AUDIT}}
| Audit log (`.agents/logs/`) | Local record of agent tool use and blocked actions (`.agents/scripts/agent-report.sh`) |
{{/if}}
{{#if MOD_TELEMETRY}}
| Telemetry | Claude Code OpenTelemetry metrics (cost, tokens, sessions) sent to `{{OTEL_ENDPOINT}}` |
{{/if}}

## If a guardrail is in your way

Don't route around it. If a rule is wrong, change it in a PR (`AGENTS.md`, `.agents/hooks/`, or your agent's settings and rules) so the whole team gets the fix.
