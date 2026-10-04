# ADR 0002: File ownership model for repeatable updates

- Status: accepted
- Date: 2026-10-04

## Context

A setup tool that runs only once drifts out of date. One that overwrites files on every run destroys team customisations, so teams stop running it. harness has to be safe to re-run forever.

## Decision

Every generated file has exactly one ownership mode:

- **file/exec:** harness owns the whole file. A sha256 is recorded in `.harness/manifest`. The file is updated only while it still matches that hash. Once a human edits it, harness writes `<file>.harness-new` and leaves the original alone.
- **block:** harness owns only the region between `>>> harness:managed` / `<<< harness:managed` markers. Used for files that are naturally shared between generated and human content (`CLAUDE.md`, `AGENTS.md`, `.gitignore`, `REVIEW.md`).
- **seed:** written once if missing, never again.

Answers live in `.harness/config` (committed). Team-specific permission rules live in `.harness/permissions` and are merged into the generated settings.

## Consequences

- `harness update` is idempotent: a second run with no changes writes nothing (tested).
- Files that are no longer generated are reported as orphans, never deleted.
- Customising a managed file is allowed, but it opts that file out of future updates. That is visible through `harness doctor` and `.harness-new` proposals.
