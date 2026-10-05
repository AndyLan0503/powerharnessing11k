# ADR 0005: Provider adapters for the coding agent, git host, and review backend

- Status: accepted
- Date: 2026-10-05
- Detail: [docs/design/providers.md](../design/providers.md)

## Context

The tool assumes Claude Code, GitHub, and the Anthropic API. Every module writes Claude-shaped and GitHub-shaped files directly, so a team on another coding agent, on GitLab, or without an Anthropic key gets little from it.

The ecosystem has converged enough to make this fixable. `AGENTS.md` is read by most coding agents. The Agent Skills folder format is shared by four of the five agents in scope. All five now offer hooks that receive a JSON payload and can block an action. Headless CLIs exist for each major model vendor.

## Decision

- The person bootstrapping a repo makes three choices: one or more coding agents, one git host (or none), and one AI review backend when review is enabled.
- Modules describe their contributions in neutral terms: a rule with globs, a skill, a role with a capability level, an allowed or denied command, a guard hook, a CI job. They no longer name a vendor's paths or formats.
- One adapter per provider turns those contributions into that provider's files. Adding a provider means adding an adapter and its tests.
- Shared content has one source: `AGENTS.md` for instructions, `.agents/skills/` for skills, `.agents/hooks/` for guard scripts, `scripts/ci/` for gate scripts.
- Support is best effort per provider. Each adapter declares what it covers, and the wizard and the generated handbook print that coverage, so a gap is always stated.

## Consequences

- Teams on Codex, Cursor, Copilot, Gemini, or GitLab get a working harness, and mixed teams share one set of rules and guard logic.
- Protection is uneven across providers where a vendor lacks a feature. This is accepted and made visible, in place of holding every provider to the weakest one.
- The file layout of a bootstrapped repo changes, for Claude-only repos too. The tool keeps no state and runs once, so existing repos are unaffected.
- The test matrix grows by provider. Hook payload formats are owned by vendors and can change, so each adapter has a contract test, and real-CLI smoke tests exist for periodic checks.
- Several facts about vendor behaviour could not be confirmed from documentation. They are listed in the design and must be verified against the real tools before the corresponding adapter ships.
