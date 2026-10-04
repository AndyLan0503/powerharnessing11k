# Contributing to harness-workflow

This repo is built by humans and coding agents together. The rules are the same for both; agents get a few extra checks.

## Workflow

1. **Open or pick an issue.** For agent work, use the *Agent task* issue template so the goal and acceptance criteria are explicit.
2. **Branch** from `main`: `<type>/<short-slug>`, e.g. `feat/export-csv`.
3. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
4. **Open a PR** using the template. Keep PRs small: under ~400 changed lines is a good target.
5. **Review.** At least one human approval is required. The author (or the human who launched the agent) owns the change through merge.
6. **Squash-merge** once CI is green.

## Local checks

- Lint: `make lint`
- Test: `make test`

## Working with agents

- Read [docs/agents/HANDBOOK.md](docs/agents/HANDBOOK.md) before delegating work to an agent.
- Agent configuration (`CLAUDE.md`, `.claude/`, `.harness/`) is code: changes go through PR review like anything else.
- The agent harness is managed by [harness](https://github.com/reclan-ai/harness-workflow). Change `.harness/config`, then run `harness update`.
