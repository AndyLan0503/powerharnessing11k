# ADR 0001: harness is a zero-dependency shell CLI

- Status: accepted
- Date: 2026-10-04

## Context

harness must run on any engineer's machine and in any CI runner, regardless of the target repo's stack. A Python repo shouldn't need Node to set up its harness, and the reverse holds too. The model we're following, Powerlevel10k, gets adoption by needing nothing but the shell you already have.

## Decision

Write harness in bash, keeping it compatible with **bash 3.2** (stock macOS) and POSIX awk/sed. Install it with `git clone` plus a symlink (`install.sh`). Generated hooks also have no hard dependencies: they use `jq` when present and fall back to python3, then sed.

## Consequences

- Install is one `curl | bash` with no package manager, and `self-update` is a `git pull`.
- Templating and JSON generation are hand-rolled (`lib/render.awk`, `lib/settings.sh`), so they are covered by tests rather than by a library.
- Contributors must follow the compatibility rules in `docs/ARCHITECTURE.md`; a macOS CI job enforces them.
- If the CLI outgrows shell (for example interactive diff merging or an API client), we revisit this. The module/template format is language-neutral, so a rewrite would not touch modules.
