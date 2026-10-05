# ADR 0003: One-shot bootstrap; the repository owns its harness

- Status: accepted
- Date: 2026-10-05
- Supersedes: [ADR 0002](0002-file-ownership-model.md)

## Context

ADR 0002 made harness safe to re-run forever: answers in `.harness/config`, checksums in `.harness/manifest`, managed blocks, `.harness-new` proposals, and `update` / `doctor` commands. That kept every bootstrapped repo tied to harness: someone had to keep running it, and harness implicitly took on responsibility for each repo's harness after setup.

We want the opposite. harness should be involved once per repository, at bootstrap. Afterwards the team does whatever it wants with the files, never needs harness again, and is responsible for maintaining its own harness. Project specifics (a particular solver, data source, or review checklist) also vary too much for harness to ship them.

## Decision

- **Create-only writes.** A file that already exists is skipped. `--force` overwrites files with the same paths; nothing is ever deleted. `.gitignore` is append-only: missing lines are added, existing ones kept.
- **No footprint.** Generated repos contain no config, manifest, managed-block markers, `harness` commands, or links and paths back to harness or its fork. A test enforces this.
- **Lifecycle tooling moves into the repo or goes away.** The audit report is `.claude/scripts/agent-report.sh`; logs live in `.claude/logs/`. `update`, `doctor`, `report`, and `self-update` are removed.
- **Project specifics are stubs, not guesses.** `--skills`, `--roles`, `--rules name=glob`, and `--dirs` create blank, correctly placed files with `TODO(team)` instructions, and `CLAUDE.md` gets a Project context section to fill in.

## Consequences

- Bootstrapping is simple and the result is easy to reason about: what you see in the PR is all there is.
- Improvements to harness reach only repositories bootstrapped afterwards. Teams that want them copy them by hand (or bootstrap into a scratch directory and compare).
- A re-run is safe but only adds missing files; it is not an upgrade path.
