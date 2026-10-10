# Roadmap

powerharnessing11k turns the team's agentic-engineering practices into a one-shot bootstrap: any repo adopts them in one command, then owns and maintains them itself.

## v0.1: foundation (this release)

- [x] p10k-style wizard with restart/quit, plus a non-interactive mode
- [x] Stack detection: Node (npm/pnpm/yarn/bun), Python (uv/poetry/pip), Go, Rust, generic
- [x] Modules: core, guardrails, quality, audit, skills, mcp, collab, ci, security, diff-guard, review, telemetry, plus profile modules ml, agentic, study, research
- [x] Profiles (software, ml, agentic, study, research) × tiers (minimal, recommended, strict), with three guard levels
- [x] Monitoring: local audit log + `.agents/scripts/agent-report.sh`, diff-guard CI, weekly digest, OpenTelemetry
- [x] Test suite on Linux, plus macOS with bash 3.2 / BSD awk
- [x] This repo runs its own harness
- [x] Apache-2.0 license; generated output is unrestricted (NOTICE)
- [x] One shot, no footprint: create-only bootstrap (`--force` to overwrite, `.gitignore` append-only); no config, manifest, managed blocks, or references back to harness in generated repos; collaborators install nothing
- [x] Fork-friendly: run from any clone or fork
- [x] Project-specific TODO(team) stubs: `--skills`, `--roles`, `--rules name=glob`, `--dirs`, and a Project context section in `CLAUDE.md`
- [x] `devtools`: Makefile as the single command surface, tiered testing guide, working Python/uv skeleton in empty repos, nightly full-tier workflow, `--cmd KEY=CMD`
- [x] `artifacts`: local data/model versioning with a committed `artifacts.lock` of hashes, `scripts/artifacts.sh`, diff-guard warning on re-pins, documented migration to DVC/object storage
- [x] Named powerharnessing11k: p11k banner, grouped write summary (`--verbose` for every file), TODO(team) files listed in the next steps, wizard covered by a pseudo-terminal test
- [x] p10k-style setup: `git clone` once, `setup.sh` from the project (empty folder → `git init`); nothing on PATH
- [x] CCAR-aligned Claude Code configuration (see `docs/CCAR-ALIGNMENT.md`): `.claude/rules/` with path scoping, `/review` and `/handoff`, skill frontmatter (`context: fork`, `allowed-tools`, `argument-hint`), scoped roles per profile, "how we work with Claude"
- [x] One standard for every PR: the gate applies the same checks whoever or whatever wrote the change; no authorship detection, labels, or required commit trailers (ADR 0004)
- [x] PR gate: diff guard + independent AI review (`claude -p`, JSON-schema findings, per-file + cross-file passes, fingerprint dedupe, confidence routing) + scorecard + recorded human override
- [x] Score keeping: gate scores and AI-review dismissals by `detected_pattern` in the weekly digest
- [x] `.mcp.json` with env-expanded credentials (strict tier)

## v0.2: hardening

- [x] Provider-neutral engine (step 1 of provider support): modules emit neutral rules, skills, roles, hooks, and permissions; a Claude Code adapter renders them. `AGENTS.md` is the source of truth, skills live in `.agents/skills/`, hooks in `.agents/hooks/`, gate scripts in `scripts/ci/`
- [x] Small root: `CLAUDE.md` in `.claude/`, `SECURITY.md` in `.github/`, review checklist and logs in `docs/`, bib file in `literature/`; a test pins the visible root entries
- [x] Codex CLI adapter: `.codex/config.toml`, command rules, hooks, and subagents from the same neutral content; path rules routed into `AGENTS.md`; multi-select agents step in the wizard; per-agent coverage in the handbook
- [x] GitHub Copilot adapter: path-scoped instruction files, custom agents, hooks (JSON decisions, arguments as string or object), CLI MCP config
- [x] `--local-only`: keep everything a bootstrap writes out of git on one machine, through `.git/info/exclude` (wizard: `l` on the last screen)
- [ ] Provider support, remaining steps: review backends, GitLab, then Cursor and Gemini. Choose the coding agents (Claude Code, Codex CLI, Cursor, Copilot, Gemini CLI), the git host (GitHub, GitLab, none), and the AI review backend. Design: `docs/design/providers.md`, ADR 0005

- [ ] First real GitHub run of the PR gate; confirm `claude -p --json-schema` output shape and inline-comment posting on a live PR
- [ ] Profile feedback loop: try each profile on a real repo and tune its rules, skills, and roles
- [ ] p10k-style polish: previews for each choice, an environment check screen, an end-of-setup tour
- [ ] `devtools`: an `eval` Makefile target; pre-commit mirroring the agent hooks (gitleaks); scaffolds for other stacks (Node, Go, Rust)
- [ ] `artifacts`: optional remote backends (DVC remote, S3/GCS sync) and an `iac` module stub (Terraform layout for the bucket and CI credentials) once remote storage exists
- [ ] Nightly latency-tolerant jobs on the Batch API (tech-debt report, test-gap report)
- [ ] `guard-bash`: fewer false positives on quoted or heredoc text. A command that only *writes* the string `curl ... | bash` into a file is blocked today; parse out quoted and heredoc bodies before matching. Seen in practice while editing this repo.
- [ ] `make dist`: versioned tarball + SHA-256 for offline or artifact-store installs; `setup.sh` from an unpacked tarball
- [ ] `docs/SECURITY-REVIEW.md`: every file harness writes and every network call it makes, for corporate intake reviews
- [ ] `supply-chain` module: internal package index config (pip/uv/npm), version cooldown, diff-guard allowlist check for new dependencies

- [ ] Pin third-party GitHub Actions to commit SHAs in the generated workflows, with Dependabot keeping them current
- [ ] Branch-protection setup through `gh api` (required checks, reviews, no force-push), opt-in
- [ ] More stacks: Java/Kotlin (Gradle/Maven), Ruby, .NET; monorepo support (per-package commands)
- [ ] Semver releases and changelog via release-please; docs recommend cloning a release tag

## v0.3: monitoring depth

- [ ] Agent-guard: scope check against the linked issue's acceptance criteria (Claude-powered, opt-in)
- [ ] Digest: CI failure causes and median time-to-merge
- [ ] `agent-report.sh --json` and an optional uploader so local audit logs feed the team dashboard
- [ ] Reference Grafana dashboard for the Claude Code OTel metrics
- [ ] Eval harness module for repos that *build* agents: regression evals in CI with score thresholds

## v0.4: organisation defaults

- [ ] Org-level defaults for the bootstrap (owners, guard level, extra permissions) read from a file in the harness fork
- [ ] Custom module directories (`HARNESS_MODULE_PATH`) so teams can ship private modules

Out of scope by design: upgrading or tracking repos after bootstrap. Each team maintains its own harness.

## Team practices (process, not code)

- Every agent PR has a human approver, and the person who launched the agent owns the change.
- `CLAUDE.md` and skills get a monthly review, driven by the friction the digest and audit log surface.
- New guardrails start in `warn` (standard) and graduate to `block` (strict) once they have proven themselves.
