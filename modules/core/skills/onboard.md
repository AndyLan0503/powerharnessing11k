---
name: onboard
description: Draft or refresh the project context that every agent reads, from the code itself. Use right after the agent setup is added, whenever AGENTS.md still has `TODO(team)` notes, or when the context may have gone stale after big changes.
argument-hint: "[area to focus on, optional]"
---

# Onboard

The **Project context** section of `AGENTS.md` is read at the start of every session, by every agent. This skill drafts it from the repository, or checks it against the repository later. A human reviews the result: you propose, they decide.

Mode: if the Project context section still contains `TODO(team)`, **draft** it. Otherwise **refresh** it.

## Gather facts

Read before you write. If your agent can hand broad exploration to a subagent, do that and keep only its summary.

- `README*`, `CONTRIBUTING*`, and any `docs/` overview.
- Manifests and lock files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, ...): the main frameworks, versions, and scripts.
- The top-level layout, the entry points, and where tests, CI workflows, and configuration live.
- `.env.example` or similar for the *shape* of configuration. Never open `.env` files or other secrets.
- `git log --oneline -30` for what changes often and what the team calls things.

If you were given an area to focus on, start there.

## Draft

Fill each entry of the Project context section:

- **What this is**: the problem, who it is for, what "done" looks like.
- **Domain terms**: words with a precise meaning in this codebase.
- **Key libraries and tools**: the ones that shape the code, with version constraints.
- **Architecture**: the main components, how data flows, where to start reading.
- **Constraints and invariants**: what must always hold.
- **Gotchas**: surprises that would cost a newcomer time.

Rules:

1. **Only what the repository shows.** For anything you cannot confirm, leave `TODO(team): <a specific question>` instead of guessing. A wrong fact here misleads every future session.
2. **Short.** About a page in total. Keep a line only if a capable engineer new to this repo would make a mistake without it.
3. **Facts, not procedures.** A multi-step procedure belongs in a skill under `.agents/skills/`; a convention for certain files belongs in a path-scoped rule. Suggest those instead of adding them here.
4. Delete the `TODO(team)` comment at the top of the section only when no entry still needs a human answer.

## Refresh

Compare each line of the section with the code. Propose removing lines that are stale, duplicated elsewhere, or obvious from the code, and adding facts the team has had to explain to agents more than once. Show the changes as a diff, each with a one-line reason.

## Also check

- **Tests.** If the repository has no tests, or none for its main behavior, say so plainly, and offer to write a few for the most important paths (with the `test-writer` subagent if there is one). Do not write them unless the user agrees.
- **Other `TODO(team)` notes.** List the files that still have them (`grep -rl 'TODO(team)' .`), and offer to draft the ones the code can answer.

## Report

- What you drafted or changed, and the files each fact came from.
- The open questions, as a short list the user can answer in one reply.
- Do not commit. The user reviews the diff and commits it like any other change.
