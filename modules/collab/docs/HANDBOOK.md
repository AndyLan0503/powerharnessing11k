# Working with coding agents in {{PROJECT_NAME}}

This handbook is the team's policy for agentic work. It belongs to the team: change it through a PR like any other file.

## Principles

1. **Agents are teammates with limits.** Agent changes follow the same PR, review, and CI path as human changes, plus extra checks and an audit trail.
2. **A human owns every agent change.** Whoever launches an agent owns its output: reviewing it, merging it, and answering for it.
3. **Context lives in the repo.** `CLAUDE.md`{{#if MULTI_AGENT}} and `AGENTS.md`{{/if}}, skills, and this handbook are versioned and reviewed like code. If an agent keeps making the same mistake, fix the context, not just the PR.
4. **Guardrails are mechanical.** Hooks, permissions, and required CI checks enforce the rules; this document explains them.

## When to use an agent

Good fits: well-specified bugs, test backfills, mechanical refactors, migrations with a clear pattern, docs, scaffolding, CI fixes.

Poor fits: ambiguous product decisions, security-sensitive code without an expert reviewer, changes with no way to verify them, sweeping multi-module redesigns.

## Writing a good agent task

- Use the **Agent task** issue template.
- State the goal and **testable** acceptance criteria.
- Point to the relevant files and prior art.
- Say what is out of scope.
- If it would be more than ~400 lines, split it.

## Reviewing agent PRs

Agent PRs are labelled `agent-authored` automatically. Review them as you would a new teammate's PR, with extra attention to:

- **Tests:** were any deleted, skipped, or weakened? The agent-guard check flags this.
- **Scope:** does the diff stay within the task?
- **Dependencies:** any new packages? Are they justified and maintained?
- **Confident-sounding claims:** verify "I ran the tests" against CI.

## Guardrails at a glance (level: {{GUARD_LEVEL}})

| Layer | What it does |
|---|---|
| Permissions (`.claude/settings.json`) | Pre-approves safe commands; denies reading secrets |
| Hooks (`.claude/hooks/`) | Block force-push, `--no-verify`, destructive deletes, secret edits{{#if GUARD_STRICT}}, CI/guardrail edits{{/if}} |
{{#if MOD_CI}}
| CI (`ci.yml`) | Lint, typecheck, and tests are required to merge |
{{/if}}
{{#if MOD_AGENT_GUARD}}
| PR gate (`pr-gate.yml`) | One required check. Labels agent PRs and flags test deletion, skipped tests, protected paths, oversized diffs, and new dependencies; posts a scorecard; `gate-override` records a human's risk acceptance |
| Weekly digest (`agent-digest.yml`) | Agent PR volume, merge rate, reverts, gate scores, and AI-review false-positive rates by pattern |
{{/if}}
{{#if MOD_REVIEW}}
| AI review (in the PR gate) | An independent Claude Code instance reviews each file, then the change as a whole, against `.github/review/criteria.md`; blocking findings fail the gate. React 👎 on false positives |
{{/if}}
{{#if MOD_AUDIT}}
| Audit log (`.claude/logs/`) | Local record of agent tool use and blocked actions (`.claude/scripts/agent-report.sh`) |
{{/if}}
{{#if MOD_TELEMETRY}}
| Telemetry | Claude Code OpenTelemetry metrics (cost, tokens, sessions) sent to `{{OTEL_ENDPOINT}}` |
{{/if}}

## If a guardrail is in your way

Don't route around it. If a rule is wrong, change it in a PR (`.claude/settings.json`, `.claude/hooks/`, or `.claude/rules/`) so the whole team gets the fix.
