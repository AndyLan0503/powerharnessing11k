# harness

**A one-shot agentic harness bootstrap for any git repository.** Think `p10k configure`, but instead of a zsh prompt it sets up everything a team needs to work well with coding agents: agent context and rules, skills, roles, guardrail hooks, CI with AI review and a quality gate, and monitoring of what agents actually do. The practices follow Anthropic's Claude Certified Architect exam guides ([how](docs/CCAR-ALIGNMENT.md)).

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/.harness-workflow
cd ~/work/my-project            # an empty folder or an existing repo
~/.harness-workflow/setup.sh    # the setup wizard
```

No install and nothing on your PATH: clone it once, like Powerlevel10k, and run `setup.sh` from the project you want to set up. In an empty folder it offers to `git init` first.

```
   _
  | |__   __ _ _ __ _ __   ___  ___ ___
  | '_ \ / _` | '__| '_ \ / _ \/ __/ __|
  | | | | (_| | |  | | | |  __/\__ \__ \
  |_| |_|\__,_|_|  |_| |_|\___||___/___/

  [1/10]  What is this repository for?

  (1)  Software engineering
       Apps, services, libraries: PR workflow, CI, security scanning, agent PR monitoring

  (2)  Data science & ML
       Notebooks, pipelines, models: reproducibility, immutable raw data, experiment log, ...

  (3)  Agentic applications
       LLM apps and agents: prompts as code, evals gate changes, tool safety, ...

  (4)  Self-paced study
       Claude as a tutor: learning plan, notes, quizzes, progress log; it hints rather than ...

  (5)  Research
       Lab notebook, literature notes, verified citations, immutable raw data, ...

  (r)  Restart from the beginning.
  (q)  Quit and do nothing.
```

Ten single-key questions: profile, stack (auto-detected), commands, which agents, how much harness (minimal / recommended / strict / custom), data and model versioning, project-specific stubs, code owners, telemetry, and confirm.

## Once per repo, then it's yours

**harness runs once, at bootstrap, and is never needed again.** It writes plain files (bash hooks, settings, rules, skills, workflows, docs) into the project and leaves nothing behind that points back to it: no config file, no manifest, no managed blocks, no `update` command. From then on the team owns and maintains its harness like any other code, and harness takes no responsibility for it.

| | Tech lead | Collaborators |
|---|---|---|
| Get harness | `git clone` it once (anywhere) | **Nothing** |
| Bootstrap the project | `setup.sh`, fill in the TODOs, commit, open a PR | Pull, as with any change |
| Day to day | Nothing | Nothing: Claude Code loads the rules, skills, roles, and hooks automatically |
| Change a guardrail, rule, or workflow | Edit the file in the project, through a PR | Same |

- **Create-only.** Existing files are never touched; only missing ones are created, and `.gitignore` only gains missing lines. `--force` overwrites files with the same paths (it never deletes anything).
- **Re-running is safe** but is not an upgrade path: it only adds files that are still missing.

## What a repo gets: a shared layer plus a profile layer

| | Shared (every profile) | Profile-specific |
|---|---|---|
| **Context** | `CLAUDE.md` (project, commands, working agreement, "how we work with Claude"); `AGENTS.md` for multi-agent repos | `.claude/rules/<profile>.md`, always loaded |
| **Path rules** | `testing.md` (test files anywhere), `github-actions.md` (`.github/**`) | `data.md`, `notebooks.md`, `prompts.md`, `evals.md`, `exercises.md`, `literature.md`, loaded only when Claude touches matching files |
| **Commands** | `/review` (independent review), `/handoff` (summary for a fresh session) | n/a |
| **Skills** | `steward`, `task-intake` (engineering profiles) | see the table below |
| **Roles** (subagents, scoped tools) | `reviewer` (fresh-context, profile-aware; all but study), `test-writer` (engineering profiles) | none: harness ships only these two near-universal roles; add domain roles in your own repo |
| **Hooks** | guard-bash, guard-paths, format-on-edit, stop-checks, audit-log, session-start | `data/raw/` read-only (ml, research); `exercises/` read-only (study) |
| **Tools** | permissions (allow your lint/test commands; deny secrets); `.mcp.json` with the GitHub MCP server (strict tier) | WebSearch pre-approved (research); Learning output style (study) |

### Profiles

| Profile | Rules focus | Skills | Seeded files |
|---|---|---|---|
| **software** | PR workflow, tests are the contract, scope, deps | `steward`, `task-intake` | n/a |
| **ml** | Immutable raw data, no data/models in git, seeds + configs, no leakage, baselines, segment-level metrics, calibration | + `experiment`, `data-audit` (forked, read-only) | `EXPERIMENTS.md`, `docs/DATA.md`, `data/README.md` |
| **agentic** | `stop_reason` loops, explicit subagent context, tool descriptions, structured tool errors, least privilege, hooks for hard rules, schema output, evals gate changes, escalation design, injection, caching | + `prompt-change`, `agent-tool` | `prompts/`, `evals/` (example cases incl. prompt injection) |
| **study** | Tutor, not ghostwriter: diagnose, hints before answers, check understanding, keep the progress log | `tutor`, `quiz` (spaced repetition), `study-plan` | `LEARNING_PLAN.md`, `PROGRESS.md`, `notes/`, `exercises/` |
| **research** | Never fabricate; claim→source provenance with dates; conflicts annotated; lab notebook; reproducible analyses | `lab-notebook`, `lit-review`, `claim-check` (forked, read-only) | `RESEARCH_LOG.md`, `references.bib`, `literature/` |

Tiers per profile: **minimal** (core, guardrails, profile module; guard relaxed), **recommended** (the profile's defaults), **strict** (adds AI review, MCP, and a stricter guard level). `setup.sh list` prints the exact module lists. `EVAL_CMD` (ml, agentic) is asked for in the commands step.

### Project-specific stubs

harness doesn't know your domain (your solver, your data sources, your review checklist), so it doesn't guess. Name what you need and it creates blank, correctly placed files with `TODO(team)` instructions for the team to fill in:

| Option | Creates |
|---|---|
| `--skills run-solver,formulate` | `.claude/skills/<name>/SKILL.md` (frontmatter, step-by-step template) |
| `--roles model-checker` | `.claude/agents/<name>.md` (read-only tools by default) |
| `--rules "solver=src/solver/** bench=benchmarks/**"` | `.claude/rules/<name>.md`, loaded only for matching paths |
| `--dirs "infra experiments"` | `<dir>/README.md` |

Every `CLAUDE.md` also gets a **Project context** section to fill in (domain terms, key libraries, architecture, invariants, gotchas).

### The software path: one command surface, tiered tests

The `devtools` module (software, ml, agentic; research from recommended):

- a **Makefile** as the single interface for humans, agents, hooks, and CI: `setup`, `lint`, `fmt`, `typecheck`, `test` (fast tier), `test-all` (full tier), `check` (everything a PR must pass);
- **`docs/TESTING.md`**: unit, integration, property-based, regression (golden), and performance tiers; determinism, explicit tolerances, reviewed golden results, pinned inputs;
- in an **empty Python repo**, a working **uv** skeleton: `pyproject.toml` (ruff, mypy strict, pytest with `integration` / `regression` / `slow` / `benchmark` markers, hypothesis, coverage), `src/<package>/`, `tests/`. `make setup && make check` passes out of the box;
- a nightly **Full tests** workflow when there is a full-tier command (`make test-all`).

An existing `Makefile` (or `makefile`, `GNUmakefile`) or `pyproject.toml` is left alone, even with `--force`; CI then calls the raw commands instead. For an existing Python project, harness proposes only the checks its configuration supports (mypy only with `[tool.mypy]`, the fast/full split only with a `slow` marker). Override any detected command with `--cmd KEY=CMD` (`install`, `lint`, `typecheck`, `test`, `full-test`, `format`, `eval`).

### Data and model versioning (local first)

The `artifacts` module (ml; research from recommended; anywhere with `--artifacts`) versions data and models without any cloud service:

- `data/` and `models/` stay out of git (their `README.md` files stay in);
- a committed **`artifacts.lock`** records the sha256 of every file, so each commit pins the exact data and models it was built and tested with;
- `scripts/artifacts.sh snapshot | verify | status | list | hash`, plus `make artifacts-verify`; tests that need the real files skip cleanly when they don't match (e.g. in CI);
- agents may verify but not re-pin (snapshot) on their own; agent guard flags PRs that change the lock;
- `docs/ARTIFACTS.md` documents the migration path to DVC or object storage (and the IaC that provisions it) once remote storage exists: the lock is the list of what to upload.

## CI/CD: one PR gate

Every PR gets a single required check, **PR gate**, made of:

- **Agent guard:**
  - detects agent-authored PRs (co-author trailer, branch prefix, or PR checkbox) and labels them;
  - flags deleted or skipped tests, removed assertions, protected-path edits, oversized diffs, new dependencies, large files, notebooks committed with outputs (ml, research), and prompt changes without eval changes (agentic).
- **AI review** (strict tier, or add the `review` module; needs `ANTHROPIC_API_KEY`):
  - a fresh, independent Claude Code instance (`claude -p`, read-only tools) reviews each changed file, then does one cross-file pass;
  - findings must match a JSON schema (`--output-format json --json-schema`) and follow the team-owned `.github/review/criteria.md`: categories to report or skip (each one can be switched off), severity definitions, and examples;
  - findings are posted inline; low-confidence ones go to "needs a human look";
  - every finding is fingerprinted, so later runs report only new issues and count still-unfixed ones without reposting.
- **Gate:**
  - blocking findings fail the check;
  - a maintainer can add the `gate-override` label to accept the risk, and the override is recorded;
  - a sticky **scorecard** comment shows the signals and a transparent score.
- **Weekly digest issue:**
  - agent PR volume, merge rate and reverts;
  - gate scores for agent vs human PRs, and overrides;
  - AI-review findings by `detected_pattern` with 👎 dismissal counts, which tell you which categories need sharper criteria or switching off.

Plus stack-aware `ci.yml` (fast tier on every PR), a nightly full-tier workflow, Conventional Commit PR titles, CodeQL, dependency review, Dependabot, `@claude` mentions, and an eval workflow for agentic repos. Make **CI** and **PR gate / gate** required in branch protection.

The gate is hardened against the PR it judges:
- every job runs its scripts and review criteria from the **base branch**;
- only this workflow's bot comments are trusted as earlier scorecards;
- a title or label edit can't cancel a running review, and a commit without a finished review waits instead of passing;
- the reviewing model never sees GitHub tokens, and the diff is fenced off as untrusted data;
- secret-shaped strings are redacted before posting;
- the PR author (or a bot) can't apply their own override.

Protect `.github/` with CODEOWNERS, and pin `CLAUDE_CODE_VERSION` in `pr-gate.yml` to a version you have tested.

## Guard levels

| | relaxed | standard | strict |
|---|:-:|:-:|:-:|
| Block `rm -rf` of `/` or `~`; block pushes to the default branch (not in solo study repos) | ✅ | ✅ | ✅ |
| Block edits to `.env*` and key files; deny reading secrets | ✅ | ✅ | ✅ |
| Block force-push, `--no-verify`, `curl \| sh`, `chmod 777`, shell access to `.env` | | ✅ | ✅ |
| Lint/typecheck must pass before the agent finishes (Stop hook) | | ✅ | ✅ |
| Block `--force-with-lease`, `reset --hard`, `git clean -f`, `gh pr merge` | | | ✅ |
| CI workflows, CODEOWNERS, `.claude/settings.json`, hooks are human-only | | | ✅ |
| `git push` asks for confirmation; agent-guard findings fail the gate | | | ✅ |

Rules that must always hold are hooks and gates; `CLAUDE.md` only guides. Every block is logged and explained to the agent: *"Blocked by guardrail: force-push rewrites shared history. If this is genuinely required, stop and ask a human to do it."*

## Monitoring

1. **Live usage** (`telemetry`): Claude Code OpenTelemetry metrics (cost, tokens, sessions, tool decisions) sent to your collector.
2. **Local audit** (`audit`): `.claude/logs/events.jsonl` (git-ignored) records each tool call, blocked action, and failed check; `.claude/scripts/agent-report.sh --days 7` summarises it.
3. **Outcomes** (PR gate): scorecards on every PR and the weekly digest.

## Commands

Run from inside the project:

```
setup.sh                 the wizard
setup.sh --yes           non-interactive: profile defaults plus any flags
setup.sh --dry-run       show what would be written
setup.sh list            profiles, tiers, and modules
setup.sh help            all options
```

Non-interactive examples:

```sh
~/.harness-workflow/setup.sh --yes --profile ml --tier strict --owners @acme/platform --agents multi
~/.harness-workflow/setup.sh --yes --stack python --artifacts \
  --skills run-solver,formulate --rules "solver=src/*/solver/**" --dirs infra
~/.harness-workflow/setup.sh --yes --profile study
```

## Using harness inside a company

Fork or import the repo into your company's GitHub org, through whatever route your security team approves, and clone *that*. Only tech leads ever touch it; collaborators never need access. Sync upstream when you choose. Generated repos never reference harness or the fork, so nothing breaks when either moves.

## Requirements

bash 3.2+ (stock macOS works), git, awk, sed. `jq` is optional for hooks, which fall back to python3 and then sed. CI scripts use the `jq` and `gh` preinstalled on GitHub runners.

## Develop

```sh
make lint   # shellcheck
make test   # tests/run.sh: every profile × tier, create-only/--force, stubs, artifacts, devtools, hooks, review + gate (stubbed claude)
```

`HARNESS_TEST_UV=1 make test` also runs `make setup && make check` inside a generated Python project (needs uv and network).

This repo uses a harness itself, bootstrapped once and maintained by hand. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to add a module or profile, [docs/CCAR-ALIGNMENT.md](docs/CCAR-ALIGNMENT.md) for the practices behind it, and [docs/ROADMAP.md](docs/ROADMAP.md) for what's next.

## License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). You can use, modify, and redistribute harness, including privately inside a company, as long as you keep the license and notices. **The files harness generates into your repository are yours**: `NOTICE` grants an additional permission to use them however you like, with no attribution required.
