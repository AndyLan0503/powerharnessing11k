<div align="center">

<pre>
          _   _   _
   _ __  / | / | | | __
  | '_ \ | | | | | |/ /
  | |_) || | | | |   <
  | .__/ |_| |_| |_|\_\
  |_|
</pre>

# powerharnessing11k

**`p10k configure`, but for your repo's AI agents.**

One wizard. Ten questions. A repository that's ready for humans and coding agents to work in together,<br>
with guardrails, CI, an AI review gate, and monitoring. Then it gets out of your way, for good.

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)
![macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Dependencies: none](https://img.shields.io/badge/dependencies-none-success)
![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D97757)

[Quick start](#-quick-start) •
[The wizard](#-the-wizard) •
[What you get](#-what-you-get) •
[Profiles](#-profiles) •
[PR gate](#-the-pr-gate) •
[FAQ](#-faq)

</div>

---

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
cd ~/work/my-project && ~/powerharnessing11k/setup.sh
```

That's the whole install. Nothing goes on your `PATH`, nothing is added to your project's dependencies, and nobody else on the team installs anything.

## ✨ Why

Working with coding agents in a shared repository goes well when a handful of things are true at once: the agent knows the project's context and rules, destructive actions are blocked rather than discouraged, every agent PR is checked by something other than the agent that wrote it, and someone can see what the agents actually did. Setting all of that up by hand takes days, and every repo ends up slightly different.

powerharnessing11k does it in about a minute, from the practices in Anthropic's Claude Certified Architect exam guides ([how they map](docs/CCAR-ALIGNMENT.md)), and then **leaves**. Everything it writes is plain files your team owns.

- 🧙 **A p10k-style wizard.** One question per screen, single-key answers, `r` to restart, `q` to quit and change nothing.
- 🎯 **Five profiles.** Software, data science & ML, agentic apps, self-paced study, and research, each in minimal / recommended / strict tiers.
- 🛡️ **Guardrails that hold.** Hooks block force-pushes, `--no-verify`, `curl | sh`, secret access, and pushes to `main`. Every block is logged and explained to the agent.
- 🔍 **An independent AI review gate.** A fresh Claude instance reviews every PR against your own criteria; a scorecard and weekly digest keep score.
- 🧪 **A clean software path.** A Makefile as the one command surface, tiered tests (fast on every PR, full nightly), and a working Python/uv skeleton in empty repos.
- 📦 **Data and model versioning, locally.** A committed `artifacts.lock` pins the exact data and models every commit used. No cloud required.
- 🧩 **Your domain, your words.** Name your skills, subagents, and rules; you get blank, correctly placed files with `TODO(team)` notes instead of guesses.
- 🚪 **One shot, no footprint.** No config file, no manifest, no `update` command, no links back to this repo. It runs once per repository and is never needed there again.

## 🚀 Quick start

**1. Clone it once**, anywhere you like (like Powerlevel10k):

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
```

**2. Run it from the project** you want to set up. An empty folder is fine: it offers to `git init` first.

```sh
mkdir opt-engine && cd opt-engine
~/powerharnessing11k/setup.sh
```

**3. Answer ten questions.** Then fill in the `TODO(team)` notes it lists, commit, and open a PR. Collaborators just pull.

Prefer no questions? Everything has a flag:

```sh
~/powerharnessing11k/setup.sh --yes --stack python --artifacts \
  --skills formulate,run-solver --roles model-checker \
  --rules "solver=src/*/solver/**" --dirs infra
```

## 🧙 The wizard

```
          _   _   _
   _ __  / | / | | | __
  | '_ \ | | | | | |/ /
  | |_) || | | | |   <
  | .__/ |_| |_| |_|\_\
  |_|

  powerharnessing11k  one-shot agentic harness configurator · v0.1.0

  [3/10]  These commands will be used by hooks, CI, and agent docs. OK?

  (1)  Use them
       install     uv sync
       lint        uv run ruff check . && uv run ruff format --check .
       typecheck   uv run mypy
       test        uv run pytest -m "not slow and not benchmark"
       full tests  uv run pytest
       format      uv run ruff format {file}

  (2)  Edit them
       Type each command; Enter keeps the default, '-' clears it

  (r)  Restart from the beginning.
  (q)  Quit and do nothing.

  Choice [1-2, r, q]:
```

| Step | Question | Notes |
|:-:|---|---|
| 1 | What is this repository for? | One of the five [profiles](#-profiles) |
| 2 | Language or toolchain? | Node, Python, Go, Rust, or generic; detected from the repo's files |
| 3 | These commands OK? | Install, lint, typecheck, fast tests, full tests, format (and eval for ml/agentic) |
| 4 | Which coding agents? | Claude Code only, or also Copilot / Codex / Cursor via a shared `AGENTS.md` |
| 5 | How much harness? | Minimal, recommended, strict, or pick modules one by one |
| 6 | Version data or model files? | Local `data/` + `models/` pinned by hash in `artifacts.lock` |
| 7 | Project-specific stubs? | Skills, subagents, path-scoped rules, folders: blank files with `TODO(team)` notes |
| 8 | Who reviews changes? | CODEOWNERS entries |
| 9 | Export telemetry? | Claude Code OpenTelemetry to your collector |
| 10 | Ready to apply | Every answer and module, one last look |

When it's done you get a short summary and your next steps:

```
  59 file(s) written

  + ./             CLAUDE.md, .gitignore, .editorconfig, Makefile, pyproject.toml, .python-version, ...
  + .claude/       hooks/ 7, commands/ 2, agents/ 3, rules/ 5, scripts/, skills/ 4, settings.json
  + docs/          TESTING.md, ARTIFACTS.md, agents/
  + src/           opt_engine/ 2
  + tests/         conftest.py, unit/
  + .github/       pull_request_template.md, ISSUE_TEMPLATE/ 3, workflows/ 7, dependabot.yml, scripts/ 2
  ...

  ✔ Bootstrapped /home/you/work/opt-engine

  Next steps (everything written is now yours; powerharnessing11k is not needed again)
    1. Fill in the TODO(team) notes in these files (find them again with: grep -rl 'TODO(team)' .)
         CLAUDE.md
         .claude/skills/run-solver/SKILL.md
         ...
    2. make setup && make check     (installs dev tools with uv, then runs every fast check)
    3. Review, commit, and open a PR:  git add -A && git commit -m 'chore: bootstrap agent harness'
    4. Protect 'main': require PR review and the CI checks (Settings → Branches)
```

Add `--verbose` to see every file, or `--dry-run` to see what would be written without writing anything.

## 📦 What you get

A software-profile, Python, recommended-tier bootstrap with data versioning and a few stubs:

```
opt-engine/
├── CLAUDE.md                  project context (TODO), commands, working agreement, how we work with Claude
├── Makefile                   setup · lint · fmt · typecheck · test · test-all · check
├── pyproject.toml             uv · ruff · mypy --strict · pytest markers · hypothesis · coverage
├── artifacts.lock             sha256 of every data/model file, committed
├── .claude/
│   ├── settings.json          permissions (allow your commands, deny secrets) + hook wiring
│   ├── hooks/                 guard-bash · guard-paths · format-on-edit · stop-checks · audit-log
│   ├── rules/                 testing · github-actions · data · artifacts · solver (yours)
│   ├── skills/                steward · task-intake · formulate (yours) · run-solver (yours)
│   ├── agents/                reviewer · test-writer · model-checker (yours)
│   ├── commands/              /review · /handoff
│   └── scripts/               agent-report.sh
├── .github/
│   ├── workflows/             ci · tests-full (nightly) · pr-gate · agent-digest · codeql · ...
│   └── scripts/               agent-guard.sh · pr-gate.sh
├── src/opt_engine/            package skeleton
├── tests/                     conftest (real-data fixture) + unit smoke test
├── data/  models/             git-ignored, except their READMEs
├── scripts/artifacts.sh       snapshot · verify · status · list · hash
├── docs/                      TESTING.md · ARTIFACTS.md · agents/HANDBOOK.md
└── infra/README.md            (yours)
```

`make setup && make check` passes on it out of the box.

### Shared layer + profile layer

| | Shared (every profile) | Profile-specific |
|---|---|---|
| **Context** | `CLAUDE.md` (project context, commands, working agreement, "how we work with Claude"); `AGENTS.md` for multi-agent repos | `.claude/rules/<profile>.md`, always loaded |
| **Path rules** | `testing.md` (test files anywhere), `github-actions.md` (`.github/**`) | `data.md`, `notebooks.md`, `prompts.md`, `evals.md`, `exercises.md`, `literature.md`, loaded only when Claude touches matching files |
| **Commands** | `/review` (independent review), `/handoff` (summary for a fresh session) | n/a |
| **Skills** | `steward`, `task-intake` (engineering profiles) | see [Profiles](#-profiles) |
| **Roles** (subagents, scoped tools) | `reviewer` (fresh-context, profile-aware; all but study), `test-writer` (engineering profiles) | none: only these two near-universal roles ship; add domain roles as stubs |
| **Hooks** | guard-bash, guard-paths, format-on-edit, stop-checks, audit-log, session-start | `data/raw/` read-only (ml, research, artifacts); `exercises/` read-only (study) |
| **Tools** | permissions (allow your lint/test commands; deny secrets); `.mcp.json` with the GitHub MCP server (strict tier) | WebSearch pre-approved (research); Learning output style (study) |

## 🎯 Profiles

| Profile | Rules focus | Skills | Seeded files |
|---|---|---|---|
| 🛠️ **software** | PR workflow, tests are the contract, scope, dependencies | `steward`, `task-intake` | Makefile, `docs/TESTING.md`, Python skeleton |
| 📊 **ml** | Immutable raw data, no data/models in git, seeds + configs, no leakage, baselines, segment-level metrics, calibration | + `experiment`, `data-audit` (forked, read-only) | `EXPERIMENTS.md`, `docs/DATA.md`, `artifacts.lock` |
| 🤖 **agentic** | `stop_reason` loops, explicit subagent context, tool descriptions, structured tool errors, least privilege, schema output, evals gate changes, injection, caching | + `prompt-change`, `agent-tool` | `prompts/`, `evals/` (example cases incl. prompt injection) |
| 📚 **study** | Tutor, not ghostwriter: diagnose, hints before answers, check understanding, keep the progress log | `tutor`, `quiz` (spaced repetition), `study-plan` | `LEARNING_PLAN.md`, `PROGRESS.md`, `notes/`, `exercises/` |
| 🔬 **research** | Never fabricate; claim→source provenance with dates; conflicts annotated; lab notebook; reproducible analyses | `lab-notebook`, `lit-review`, `claim-check` (forked, read-only) | `RESEARCH_LOG.md`, `references.bib`, `literature/` |

Each profile comes in three tiers: **minimal** (core, guardrails, profile module; relaxed guard), **recommended** (the profile's defaults), and **strict** (adds AI review, MCP, and a stricter guard). `setup.sh list` prints the exact modules.

### 🧩 Project-specific stubs

powerharnessing11k doesn't know your domain (your solver, your data sources, your review checklist), so it doesn't guess. Name what you need and it creates blank, correctly placed files that tell the team what to write:

| Option | Creates |
|---|---|
| `--skills formulate,run-solver` | `.claude/skills/<name>/SKILL.md` with frontmatter and a step-by-step template |
| `--roles model-checker` | `.claude/agents/<name>.md`, read-only tools by default |
| `--rules "solver=src/solver/** bench=benchmarks/**"` | `.claude/rules/<name>.md`, loaded only for matching paths |
| `--dirs "infra experiments"` | `<dir>/README.md` |

Every `CLAUDE.md` also gets a **Project context** section to fill in: domain terms, key libraries, architecture, invariants, gotchas.

### 🧪 The software path

The `devtools` module (software, ml, agentic; research from recommended) gives everyone, human or agent, the same verbs:

| Target | Runs |
|---|---|
| `make setup` | install dependencies and dev tools |
| `make lint` / `make fmt` | static checks / reformat |
| `make typecheck` | type checks (skipped if none are configured) |
| `make test` | the **fast tier**: what every change and every PR must pass |
| `make test-all` | the **full tier**: adds slow, regression, and benchmark tests (nightly in CI) |
| `make check` | lint + typecheck + test, the PR bar |

`docs/TESTING.md` lays out the tiers (unit, integration, property-based, regression against golden results, performance) and the rules: determinism, explicit tolerances, golden results reviewed and never regenerated to go green, pinned inputs.

In an **empty Python repo** you also get a working uv project (`pyproject.toml`, `src/<package>/`, `tests/`). An existing `Makefile` or `pyproject.toml` is never touched, even with `--force`; CI then calls your own commands. Override any detected command with `--cmd KEY=CMD`.

### 📦 Data and model versioning, local first

The `artifacts` module (ml; research from recommended; anywhere with `--artifacts`):

- keeps `data/` and `models/` out of git (their READMEs stay in);
- records the sha256 of every file in a committed **`artifacts.lock`**, so a commit pins the exact data and models it was built and tested with;
- ships `scripts/artifacts.sh snapshot | verify | status | list | hash` and `make artifacts-verify`; tests that need the real files skip cleanly when they don't match (in CI, for example);
- lets agents verify but not re-pin on their own, and flags PRs that change the lock;
- documents the move to DVC or object storage (and the IaC behind it) in `docs/ARTIFACTS.md`: when remote storage arrives, the lock is the upload list.

## 🔍 The PR gate

Every PR gets one required check, **PR gate**:

- **Agent guard** detects agent-authored PRs (co-author trailer, branch prefix, or PR checkbox), labels them, and flags deleted or skipped tests, removed assertions, protected-path edits, oversized diffs, new dependencies, large files, re-pinned artifacts, notebooks with outputs, and prompt changes without eval changes.
- **AI review** (strict tier, or add the `review` module; needs `ANTHROPIC_API_KEY`): a fresh Claude Code instance (`claude -p`, read-only tools) reviews each changed file, then does one cross-file pass.
  - Findings follow a JSON schema and your team's `.github/review/criteria.md`: categories to report or skip, severity definitions, and examples.
  - Findings are posted inline; low-confidence ones go to "needs a human look".
  - Every finding is fingerprinted, so later runs report only what's new.
- **Gate:** blocking findings fail the check. A maintainer can add `gate-override` to accept the risk, and the override is recorded. A sticky **scorecard** shows every signal and a transparent score.
- **Weekly digest:** agent PR volume, merge rate and reverts; gate scores for agent vs human PRs; AI-review findings by pattern with 👎 dismissal counts, which show which criteria need sharpening.

Plus a stack-aware `ci.yml` (fast tier on every PR), a nightly full-tier workflow, Conventional Commit PR titles, CodeQL, dependency review, Dependabot, `@claude` mentions, and an eval workflow for agentic repos. Make **CI** and **PR gate / gate** required in branch protection.

<details>
<summary><b>How the gate is hardened against the PR it judges</b></summary>

- Every job runs its scripts and review criteria from the **base branch**.
- Only this workflow's own bot comments are trusted as earlier scorecards.
- A title or label edit can't cancel a running review, and a commit without a finished review waits instead of passing.
- The reviewing model never sees GitHub tokens, and the diff is fenced off as untrusted data.
- Secret-shaped strings are redacted before posting.
- The PR author (or a bot) can't apply their own override.

Protect `.github/` with CODEOWNERS, and pin `CLAUDE_CODE_VERSION` in `pr-gate.yml` to a version you have tested.

</details>

## 🛡️ Guard levels

| | relaxed | standard | strict |
|---|:-:|:-:|:-:|
| Block `rm -rf` of `/` or `~`; block pushes to the default branch (not in solo study repos) | ✅ | ✅ | ✅ |
| Block edits to `.env*` and key files; deny reading secrets | ✅ | ✅ | ✅ |
| Block force-push, `--no-verify`, `curl \| sh`, `chmod 777`, shell access to `.env` | | ✅ | ✅ |
| Lint and typecheck must pass before the agent finishes (Stop hook) | | ✅ | ✅ |
| Block `--force-with-lease`, `reset --hard`, `git clean -f`, `gh pr merge` | | | ✅ |
| CI workflows, CODEOWNERS, `.claude/settings.json`, and hooks are human-only | | | ✅ |
| `git push` asks for confirmation; agent-guard findings fail the gate | | | ✅ |

Rules that must always hold are hooks and gates; `CLAUDE.md` only guides. Every block is logged and explained to the agent:

> Blocked by guardrail: force-push rewrites shared history. If this is genuinely required, stop and ask a human to do it.

## 📈 Monitoring

1. **Live usage** (`telemetry`): Claude Code OpenTelemetry metrics (cost, tokens, sessions, tool decisions) sent to your collector.
2. **Local audit** (`audit`): `.claude/logs/events.jsonl` (git-ignored) records each tool call, blocked action, and failed check; `.claude/scripts/agent-report.sh --days 7` summarises it.
3. **Outcomes** (PR gate): a scorecard on every PR, and the weekly digest.

## ⌨️ Command reference

```
setup.sh [configure] [options]   the wizard (default)
setup.sh list                    profiles, tiers, and modules
setup.sh version | help
```

| Option | |
|---|---|
| `-C, --target DIR` | repository to bootstrap (default: current directory) |
| `-y, --yes` | non-interactive: profile defaults plus any flags |
| `-n, --dry-run` | show what would be written, write nothing |
| `-f, --force` | overwrite files that already exist (never your `Makefile`, `pyproject.toml`, or code) |
| `--verbose` | list every file instead of the grouped summary |
| `--profile NAME` | `software` · `ml` · `agentic` · `study` · `research` |
| `--tier NAME` | `minimal` · `recommended` · `strict` |
| `--stack NAME` | `node` · `python` · `go` · `rust` · `generic` (default: detected) |
| `--modules LIST` | comma-separated modules, overriding the tier |
| `--guard LEVEL` | `relaxed` · `standard` · `strict` |
| `--agents KIND` | `claude` · `multi` (adds `AGENTS.md`) |
| `--owners LIST` | CODEOWNERS entries, e.g. `"@acme/platform"` |
| `--otel URL` | OTLP endpoint; enables telemetry |
| `--artifacts` / `--no-artifacts` | local data/model versioning on or off |
| `--cmd KEY=CMD` | override a command: `install` `lint` `typecheck` `test` `full-test` `format` `eval` |
| `--skills` `--roles` `--rules` `--dirs` | [project-specific stubs](#-project-specific-stubs) |

## ❓ FAQ

<details>
<summary><b>Do my teammates need to install anything?</b></summary>

No. Only whoever bootstraps the repo runs powerharnessing11k. Everything it writes is committed to the project: hooks are plain bash (no `jq` needed), and Claude Code picks up the rules, skills, roles, and hooks automatically. Collaborators clone or pull like any other change.

</details>

<details>
<summary><b>How do I update a repo's harness later?</b></summary>

You edit it, like any other code in the repo, through a PR. powerharnessing11k is deliberately one-shot: there's no config file, manifest, or `update` command, and nothing in your repo refers back to it. Re-running it only adds files that are missing. To pick up something new from a later version, bootstrap a scratch folder and copy what you want.

</details>

<details>
<summary><b>Will it overwrite my files?</b></summary>

No. It only creates files that don't exist, and `.gitignore` only gains the lines it's missing. `--force` overwrites files with the same paths as its own, but never your `Makefile`, `pyproject.toml`, or source code, and it never deletes anything. Try `--dry-run` first if you're unsure.

</details>

<details>
<summary><b>Does it work with agents other than Claude Code?</b></summary>

Choose "Claude Code + others" (or `--agents multi`) and the shared guidance goes in `AGENTS.md`, which Copilot, Codex, Cursor, and others read; `CLAUDE.md` imports it. Hooks, skills, and subagents are Claude Code features; CI checks and the PR gate apply to every PR whoever wrote it.

</details>

<details>
<summary><b>My company blocks public GitHub. Can I still use it?</b></summary>

Yes. Fork or import the repo into your company's GitHub, through whatever route your security team approves, and clone that. Only people bootstrapping repos ever need access. Generated repos never reference powerharnessing11k or your fork, so nothing breaks when either moves.

</details>

<details>
<summary><b>Why bash?</b></summary>

So it runs anywhere with nothing to install: stock macOS bash 3.2, `git`, `awk`, and `sed`. CI tests it on Linux and on macOS with `/bin/bash`. See [ADR 0001](docs/adr/0001-zero-dependency-shell-cli.md).

</details>

<details>
<summary><b>How do I uninstall it?</b></summary>

`rm -rf ~/powerharnessing11k`. Repositories you bootstrapped are unaffected; they never depended on it.

</details>

<details>
<summary><b>Why "powerharnessing11k"?</b></summary>

It's a spinoff of [Powerlevel10k](https://github.com/romkatv/powerlevel10k): the same one-time, wizard-driven setup experience, aimed at a repository's agent harness instead of a zsh prompt. And it goes to 11. It is not affiliated with Powerlevel10k or its author.

</details>

## 📋 Requirements

bash 3.2+ (stock macOS works), git, awk, and sed. `jq` is optional for hooks, which fall back to python3 and then sed. The generated CI uses the `jq` and `gh` preinstalled on GitHub runners; the AI review needs an `ANTHROPIC_API_KEY` secret.

## 🧑‍💻 Development

```sh
make lint   # shellcheck
make test   # tests/run.sh: every profile × tier, the wizard (via a pseudo-terminal), create-only and --force,
            # stubs, artifacts, devtools, hooks, review + gate (with a stubbed claude)
```

`HARNESS_TEST_UV=1 make test` also runs `make setup && make check` inside a generated Python project (needs uv and network access).

Start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to add a module or profile. [docs/CCAR-ALIGNMENT.md](docs/CCAR-ALIGNMENT.md) explains the practices behind it, [docs/adr/](docs/adr/) the key decisions, and [docs/ROADMAP.md](docs/ROADMAP.md) what's next. This repo uses a harness itself, bootstrapped once and maintained by hand.

## 🙏 Acknowledgements

- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) by Roman Perepelitsa, for showing how good a one-time configuration wizard can feel.
- Anthropic's [Claude Code](https://docs.anthropic.com/en/docs/claude-code) documentation and the Claude Certified Architect exam guides, for the practices.

## 📄 License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). You can use, modify, and redistribute powerharnessing11k, including privately inside a company, as long as you keep the license and notices.

**The files it generates into your repository are yours.** `NOTICE` grants an additional permission to use them however you like, with no attribution required.
