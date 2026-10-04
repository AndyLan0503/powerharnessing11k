# Roadmap

harness turns the team's agentic-engineering practices into a tool that any repo can adopt in one command and keep up to date.

## v0.1: foundation (this release)

- [x] p10k-style wizard with restart/quit, plus a non-interactive mode
- [x] Stack detection: Node (npm/pnpm/yarn/bun), Python (uv/poetry/pip), Go, Rust, generic
- [x] Reproducible config (`.harness/config`) and safe updates (manifest checksums, managed blocks, `.harness-new` proposals)
- [x] Modules: core, guardrails, quality, audit, skills, mcp, collab, ci, security, agent-guard, review, telemetry, plus profile modules ml, agentic, study, research
- [x] Profiles (software, ml, agentic, study, research) × tiers (minimal, recommended, strict), with three guard levels
- [x] Monitoring: local audit log + `.harness/report.sh`, agent-guard CI, weekly digest, OpenTelemetry
- [x] `doctor`, `report`, `list`, `self-update`
- [x] Test suite on Linux, plus macOS with bash 3.2 / BSD awk
- [x] This repo runs its own harness
- [x] Apache-2.0 license; generated output is unrestricted (NOTICE)
- [x] Maintainer-only tool: generated repos are self-contained (`.harness/README.md`, `.harness/report.sh`); collaborators install nothing
- [x] Fork-friendly: run from any clone or fork; fork-aware links in generated docs
- [x] p10k-style setup: `git clone` once, `setup.sh` from the project (empty folder → `git init`); nothing on PATH
- [x] CCAR-aligned Claude Code configuration (see `docs/CCAR-ALIGNMENT.md`): `.claude/rules/` with path scoping, `/review` and `/handoff`, skill frontmatter (`context: fork`, `allowed-tools`, `argument-hint`), scoped roles per profile, "how we work with Claude"
- [x] PR gate: agent guard + independent AI review (`claude -p`, JSON-schema findings, per-file + cross-file passes, fingerprint dedupe, confidence routing) + scorecard + recorded human override
- [x] Score keeping: gate scores and AI-review dismissals by `detected_pattern` in the weekly digest
- [x] `.mcp.json` with env-expanded credentials (strict tier)

## v0.2: hardening

- [ ] First real GitHub run of the PR gate; confirm `claude -p --json-schema` output shape and inline-comment posting on a live PR
- [ ] Profile feedback loop: try each profile on a real repo and tune its rules, skills, and roles
- [ ] p10k-style polish: previews for each choice, an environment check screen, an end-of-setup tour
- [ ] `devtools` module: generated Makefile targets (setup/lint/fmt/test/check/eval) that CI, hooks, and docs all call; pre-commit mirroring the agent hooks (gitleaks); per-stack linter configs
- [ ] Nightly latency-tolerant jobs on the Batch API (tech-debt report, test-gap report)
- [ ] `guard-bash`: fewer false positives on quoted or heredoc text. A command that only *writes* the string `curl ... | bash` into a file is blocked today; parse out quoted and heredoc bodies before matching. Seen in practice while editing this repo.
- [ ] CI drift check without the tool: a committed `.harness/verify.sh` that fails when generated files no longer match `.harness/manifest`, or when `config`/`permissions` changed without regeneration
- [ ] `make dist`: versioned tarball + SHA-256 for offline or artifact-store installs; `setup.sh` from an unpacked tarball
- [ ] `docs/SECURITY-REVIEW.md`: every file harness writes and every network call it makes, for corporate intake reviews
- [ ] `supply-chain` module: internal package index config (pip/uv/npm), version cooldown, agent-guard allowlist check for new dependencies

- [ ] Pin third-party GitHub Actions to commit SHAs (`harness pin`), with Dependabot keeping them current
- [ ] `harness diff`: show a unified diff for each `.harness-new` proposal, with interactive accept/reject
- [ ] Branch-protection setup through `gh api` (required checks, reviews, no force-push), opt-in
- [ ] More stacks: Java/Kotlin (Gradle/Maven), Ruby, .NET; monorepo support (per-package commands)
- [ ] Semver releases and changelog via release-please; docs recommend cloning a release tag

## v0.3: monitoring depth

- [ ] Agent-guard: scope check against the linked issue's acceptance criteria (Claude-powered, opt-in)
- [ ] Digest: CI failure causes on agent PRs, median time-to-merge, agent vs. human revert rate
- [ ] `harness report --json` and an optional uploader so local audit logs feed the team dashboard
- [ ] Reference Grafana dashboard for the Claude Code OTel metrics
- [ ] Eval harness module for repos that *build* agents: regression evals in CI with score thresholds

## v0.4: fleet

- [ ] Org-level defaults: a shared `harness.config` (owners, guard level, extra permissions) that repos inherit
- [ ] `harness fleet status`: drift and version across many repos
- [ ] Custom module directories (`HARNESS_MODULE_PATH`) so teams can ship private modules

## Team practices (process, not code)

- Every agent PR has a human approver, and the person who launched the agent owns the change.
- `CLAUDE.md` and skills get a monthly review, driven by the friction the digest and audit log surface.
- New guardrails start in `warn` (standard) and graduate to `block` (strict) once they have proven themselves.
