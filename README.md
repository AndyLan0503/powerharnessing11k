```
           _   _   _
   _ __   / | / | | | __
  | '_ \  | | | | | |/ /
  | |_) | | | | | |   <
  | .__/  |_| |_| |_|\_\
  |_|
```

<div align="center">

# powerharnessing11k

**`p10k configure`, but for your repo's AI agents.**

One wizard, a few questions. A repository that's ready for humans and coding agents to work in together,<br>
with guardrails, skills, and monitoring, plus CI and a PR gate if you want them. Then it gets out of your way, for good.

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)
![macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Dependencies: none](https://img.shields.io/badge/dependencies-none-success)
![Agents: Claude Code | Codex CLI | GitHub Copilot](https://img.shields.io/badge/agents-Claude%20Code%20%7C%20Codex%20CLI%20%7C%20Copilot-D97757)

[Install](#-install) •
[Quick start](#-quick-start) •
[The wizard](#-the-wizard) •
[What you get](#-what-you-get) •
[Agents](#-coding-agents) •
[Profiles](#-profiles) •
[PR gate](#-the-pr-gate) •
[Runbook](docs/RUNBOOK.md) •
[FAQ](#-faq)

</div>

---

**Install** (once, anywhere on your machine):

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
```

On Windows, or missing git? See the [install steps for each platform](#-install).

**Run** from inside the project you want to set up. It can be an existing repository or a new, empty folder:

```sh
cd ~/work/my-project
~/powerharnessing11k/setup.sh
```

Nothing goes on your `PATH`, nothing is added to your project's dependencies, and nobody else on the team installs anything.

**New to harness engineering?** Read the [runbook](docs/RUNBOOK.md) first: ten minutes on the ideas (what a harness is, and why guidance and enforcement are different things), then a step-by-step setup for your own project. To look before you commit to anything, add `--dry-run` (shows what would be written) or `--local-only` (writes it, but keeps it out of git on your machine).

## ✨ Why

Working with coding agents in a shared repository goes well when a handful of things are true at once: the agent knows the project's context and rules, destructive actions are blocked rather than discouraged, every PR is checked by something other than the agent that wrote it, and someone can see what the agents actually did. Setting all of that up by hand takes days, and every repo ends up slightly different.

powerharnessing11k does it in about a minute and then **leaves**. Everything it writes is plain files your team owns, and none of it is tied to one vendor: Claude Code, Codex CLI, and GitHub Copilot share one `AGENTS.md`, one set of skills, and one set of guard scripts. The [runbook](docs/RUNBOOK.md) explains the practices behind it; [CCAR-ALIGNMENT.md](docs/CCAR-ALIGNMENT.md) maps them to Anthropic's Claude Certified Architect exam guides, one of the sources they draw on.

- 🧙 **A p10k-style wizard.** One question per screen: press a key to mark your answer, Enter to confirm it, `r` to restart, `q` to quit and change nothing.
- 🎯 **Five profiles.** Software, data science & ML, agentic apps, self-paced study, and research, each in minimal / recommended / strict tiers.
- 🛡️ **Guardrails that hold.** Hooks block force-pushes, `--no-verify`, `curl | sh`, secret access, and pushes to `main`. Every block is logged and explained to the agent.
- 📝 **Context drafted from your code.** The `onboard` skill has your agent fill in the project context from the repository for you to review, and check it for staleness later.
- 🔍 **One PR gate for every change.** A diff guard flags deleted tests, weakened assertions, protected-path edits, and oversized diffs, whoever wrote the change; a scorecard and weekly digest keep score. An independent AI review can join it (strict tier). Opt-in, like every GitHub Actions workflow here.
- 🧪 **A software path when you want it.** In the strict tier: a Makefile as the one command surface, tiered tests (fast on every PR, full nightly), and a working Python/uv skeleton in empty repos.
- 📦 **Data and model versioning, locally.** A committed `artifacts.lock` pins the exact data and models every commit used. No cloud required.
- 🧩 **Your domain, your words.** Name your skills, subagents, and rules; you get blank, correctly placed files with `TODO(team)` notes instead of guesses.
- 🚪 **One shot, no footprint.** No config file, no manifest, no `update` command, no links back to this repo. It runs once per repository and is never needed there again.

## 📥 Install

Clone it once, anywhere you like (like Powerlevel10k). It needs bash, git, awk, and sed, and nothing else. Pick your platform:

<details open>
<summary><b>macOS</b></summary>

Everything it needs ships with macOS, apart from git. If `git --version` asks you to install the command line developer tools, accept. Then:

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
```

</details>

<details>
<summary><b>Linux</b></summary>

bash, awk, and sed come with every common distribution. Install git if you don't have it:

```sh
sudo apt install git    # Debian, Ubuntu
sudo dnf install git    # Fedora, RHEL
```

Then:

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
```

</details>

<details>
<summary><b>Windows</b></summary>

The tool and the hooks it installs are bash scripts. Bash comes with Git for Windows as **Git Bash**.

1. Install [Git for Windows](https://gitforwindows.org/), from the website or in PowerShell:

   ```powershell
   winget install --id Git.Git -e
   ```

2. Turn on **Developer Mode** in Windows Settings, so git can create symbolic links.
3. Open **Git Bash** from the Start menu and run:

   ```sh
   git config --global core.symlinks true
   git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
   ```

Run the commands in the rest of this README from Git Bash. Already use WSL? Follow the Linux steps inside it instead. See also [Does it work on Windows?](#-faq)

</details>

To update later: `git -C ~/powerharnessing11k pull`.

## 🚀 Quick start

**1. Run it from the project** you want to set up. An empty folder is fine: it offers to `git init` first.

```sh
mkdir opt-engine && cd opt-engine
~/powerharnessing11k/setup.sh
```

**2. Answer a few questions.** Then fill in the `TODO(team)` notes it lists (or ask your agent to run the `onboard` skill, which drafts the project context from your code), commit, and open a PR. Collaborators just pull.

Prefer no questions? Everything has a flag. Run this from inside the project folder too:

```sh
~/powerharnessing11k/setup.sh --yes --stack python --artifacts --actions \
  --skills formulate,run-solver --roles model-checker \
  --rules "solver=src/*/solver/**" --dirs infra
```

## 🧙 The wizard

<p align="center">
  <img src="docs/demo/wizard.gif" alt="The powerharnessing11k wizard setting up an empty folder: eleven questions, each answer marked and then confirmed with Enter, then a summary of the files written and the next steps" width="900">
</p>

Press a key to mark an answer, then Enter to confirm it; the marked option is highlighted, so you can change your mind first. `r` restarts and `q` quits without writing anything, on every screen.

| Step | Question | Notes |
|:-:|---|---|
| 1 | What is this repository for? | One of the five [profiles](#-profiles) |
| 2 | Language or toolchain? | Node, Python, Go, Rust, or generic; detected from the repo's files |
| 3 | These commands OK? | Install, lint, typecheck, fast tests, full tests, format (and eval for ml/agentic) |
| 4 | Which coding agents? | A checklist: Claude Code, Codex CLI, GitHub Copilot. Pick every one your team uses |
| 5 | How much harness? | Minimal, recommended, strict, or pick modules one by one |
| 6 | Add GitHub Actions workflows? | No by default. Yes adds the tier's workflows, such as CI and the [PR gate](#-the-pr-gate). Not asked after Custom |
| 7 | Version data or model files? | Local `data/` + `models/` pinned by hash in `artifacts.lock` |
| 8 | Project-specific stubs? | Skills, subagents, path-scoped rules, folders: blank files with `TODO(team)` notes |
| 9 | Who reviews changes? | CODEOWNERS entries |
| 10 | Export telemetry? | Claude Code OpenTelemetry to your collector (asked only when Claude Code is selected) |
| 11 | Ready to apply | Every answer and module, and what each selected agent does and doesn't get |

When it's done you get a short summary and your next steps:

```
  51 file(s) written

  + ./             .gitignore, .gitattributes, .editorconfig, artifacts.lock, CONTRIBUTING.md, AGENTS.md
  + .claude/       CLAUDE.md, agents/ 3, rules/ 5, skills, settings.json
  + .agents/       hooks/ 7, skills/ 7, scripts/
  + scripts/       artifacts.sh, ci/ 2
  + docs/          ARTIFACTS.md, agents/
  + .github/       SECURITY.md, pull_request_template.md, ISSUE_TEMPLATE/ 3, workflows/ 4
  ...

  ✔ Bootstrapped /home/you/work/opt-engine

  Next steps (everything written is now yours; powerharnessing11k is not needed again)
    1. Fill in the TODO(team) notes in these files (find them again with: grep -rl 'TODO(team)' .)
         AGENTS.md
         .agents/skills/run-solver/SKILL.md
         ...
       Or ask your coding agent to run the onboard skill: it drafts the project context from your code and helps with the rest.
    2. Create the project itself: there is no pyproject.toml yet.
    3. Review, commit, and open a PR:  git add -A && git commit -m 'chore: bootstrap agent harness'
    4. Protect 'main': require PR review and the CI checks (Settings → Branches)
```

Add `--verbose` to see every file, or `--dry-run` to see what would be written without writing anything.

## 📦 What you get

A software-profile, Python, recommended-tier bootstrap with data versioning and a few stubs:

```
opt-engine/
├── AGENTS.md                  the source of truth: project context (TODO), commands, working agreement
├── CONTRIBUTING.md            how humans and agents work together here
├── artifacts.lock             sha256 of every data/model file, committed
├── .agents/                   shared by every coding agent
│   ├── skills/                onboard · steward · task-intake · review · handoff · formulate (yours) · run-solver (yours)
│   ├── hooks/                 guard-bash · guard-paths · format-on-edit · stop-checks · audit-log
│   └── scripts/               agent-report.sh
├── .claude/                   Claude Code's own files
│   ├── CLAUDE.md              one line that matters: @../AGENTS.md
│   ├── settings.json          permissions (allow your commands, deny secrets) + hook wiring
│   ├── rules/                 testing · github-actions · data · artifacts · solver (yours)
│   ├── agents/                reviewer · test-writer · model-checker (yours)
│   └── skills -> ../.agents/skills
├── .github/
│   └── workflows/             ci · tests-full (nightly) · pr-gate · pr-digest
├── scripts/
│   ├── ci/                    diff-guard.sh · pr-gate.sh (the PR gate's scripts)
│   └── artifacts.sh           snapshot · verify · status · list · hash
├── data/  models/             git-ignored, except their READMEs
├── docs/                      ARTIFACTS.md · agents/HANDBOOK.md
└── infra/README.md            (yours)
```

The **strict** tier adds a `Makefile`, `docs/TESTING.md`, and in an empty Python repo a working uv project (`pyproject.toml`, `src/`, `tests/`, with `make setup && make check` passing out of the box), plus CodeQL, dependency review, Dependabot, the AI review, and MCP.

The root stays small on purpose. Only what tools require there is visible (`AGENTS.md`, `CONTRIBUTING.md`, the build files, `artifacts.lock`); everything else lives in the hidden folder of the tool that reads it, or in `docs/` and `scripts/`.

### Shared layer + profile layer

| | Shared (every profile) | Profile-specific |
|---|---|---|
| **Context** | `AGENTS.md` (project context, commands, working agreement, "how we work with coding agents"), read by every agent; `.claude/CLAUDE.md` imports it | the profile's always-on rules, inside `AGENTS.md` |
| **Path rules** | `testing.md` (test files anywhere), `github-actions.md` (`.github/**`) | `data.md`, `notebooks.md`, `prompts.md`, `evals.md`, `exercises.md`, `literature.md`, loaded only when the agent touches matching files |
| **Skills** | `onboard` (draft or refresh the project context from the code), `review` (independent review), `handoff` (summary for a fresh session), `steward`, `task-intake` (engineering profiles) | see [Profiles](#-profiles) |
| **Roles** (subagents, scoped tools) | `reviewer` (fresh-context, profile-aware; all but study), `test-writer` (engineering profiles) | none: only these two near-universal roles ship; add domain roles as stubs |
| **Hooks** | guard-bash, guard-paths, format-on-edit, stop-checks, audit-log, session-start | `data/raw/` read-only (ml, research, artifacts); `exercises/` read-only (study) |
| **Tools** | permissions (allow your lint/test commands; deny secrets); the GitHub MCP server in each selected agent's own config (strict tier) | WebSearch pre-approved (research); Learning output style (study) |

## 🤝 Coding agents

Choose the agents your team uses (`--agents claude,codex,copilot`, or the checklist in the wizard). Shared content is written once; each agent then gets its own files in its own format.

| | Claude Code | Codex CLI | GitHub Copilot |
|---|---|---|---|
| Project instructions | `.claude/CLAUDE.md`, an import of `AGENTS.md` | `AGENTS.md`, read directly | `AGENTS.md`, read directly; `.github/copilot-instructions.md` points other IDEs at it |
| Skills | `.claude/skills`, a link to `.agents/skills/` | `.agents/skills/`, read directly | `.agents/skills/`, read directly |
| Path-scoped rules | `.claude/rules/*.md`, loaded only for matching files | inside `AGENTS.md`, each under a heading naming its paths (always loaded) | `.github/instructions/*.instructions.md`, loaded only for matching files |
| Subagents | `.claude/agents/*.md`, with a tool list per role | `.codex/agents/*.toml`, with a sandbox level per role | `.github/agents/*.agent.md`, with a tool list per agent |
| Model tier per role (`fast`, `standard`, `deep`) | a model alias (`haiku`, `sonnet`, `opus`) | a reasoning effort (`low`, `medium`, `high`) | none: agents use the session's model |
| Command permissions | allow, ask, and deny lists in `.claude/settings.json` | prompt and forbid rules in `.codex/rules/default.rules`; everything else runs inside the sandbox set in `.codex/config.toml` | none at repository level; the guard hooks do the blocking |
| Guard hooks | wired in `.claude/settings.json` | wired in `.codex/hooks.json` | wired in `.github/hooks/guardrails.json` |
| Lint must pass before finishing | yes | yes | yes (CLI and cloud agent) |
| Team MCP servers | `.mcp.json` | `.codex/config.toml` | `.github/mcp.json` for the CLI; repository settings for the cloud agent |
| Usage telemetry | optional OpenTelemetry export | not set up | not set up |

All three call the same scripts in `.agents/hooks/`, so a blocked command is blocked whichever agent runs it.

Things to know about Codex CLI:

- It loads `.codex/` only for a project you have trusted, and runs a project hook only after you approve it with `/hooks`. It asks again whenever a hook changes. Until then the hooks do nothing.
- It has no per-file read rules at project level. Reads of secret files through the shell are still blocked by the guard hook.

Things to know about GitHub Copilot:

- The CLI loads repository hooks once you trust the folder. The cloud agent reads hooks, custom agents, and instructions from the default branch, so they take effect after the bootstrap PR is merged.
- Copilot cannot pre-approve or deny commands from a file in the repository. The guard hooks block what must be blocked; everything else follows each person's own approval settings.
- In VS Code agent mode the same hooks file is loaded, but VS Code talks to hooks in a different format that this setup has not been verified against. Treat hooks there as best effort; the PR gate still applies.

The generated `docs/agents/HANDBOOK.md` carries the same table for the agents you picked.

## 🎯 Profiles

| Profile | Rules focus | Skills | Seeded files |
|---|---|---|---|
| 🛠️ **software** | PR workflow, tests are the contract, scope, dependencies | `steward`, `task-intake` | none by default; strict adds a Makefile, `docs/TESTING.md`, and a Python skeleton |
| 📊 **ml** | Immutable raw data, no data/models in git, seeds + configs, no leakage, baselines, segment-level metrics, calibration | + `experiment`, `data-audit` (forked, read-only) | `docs/EXPERIMENTS.md`, `docs/DATA.md`, `artifacts.lock` |
| 🤖 **agentic** | `stop_reason` loops, explicit subagent context, tool descriptions, structured tool errors, least privilege, schema output, evals gate changes, injection, caching | + `prompt-change`, `agent-tool` | `prompts/`, `evals/` (example cases incl. prompt injection) |
| 📚 **study** | Tutor, not ghostwriter: diagnose, hints before answers, check understanding, keep the progress log | `tutor`, `quiz` (spaced repetition), `study-plan` | `LEARNING_PLAN.md`, `PROGRESS.md`, `notes/`, `exercises/` |
| 🔬 **research** | Never fabricate; claim→source provenance with dates; conflicts annotated; lab notebook; reproducible analyses | `lab-notebook`, `lit-review`, `claim-check` (forked, read-only) | `docs/RESEARCH_LOG.md`, `literature/` (with `references.bib`) |

Each profile comes in three tiers: **minimal** (core, guardrails, profile module; relaxed guard), **recommended** (the profile's defaults: quality checks, audit log, skills, and collaboration files), and **strict** (adds the Makefile and test tiers, MCP, and a stricter guard). `setup.sh list` prints the exact modules.

GitHub Actions workflows are opt-in at every tier (`--actions`, or "Yes" in the wizard). With them, each tier adds its workflows; for software, ml, and agentic repos, minimal gets CI, recommended gets CI and the [PR gate](#-the-pr-gate), and strict also gets security scanning and AI review (with its checklist, `docs/REVIEW.md`). `setup.sh list` shows what `--actions` adds for every profile. Without them, nothing runs on GitHub: the harness lives in the repo and its agents.

### 🧩 Project-specific stubs

powerharnessing11k doesn't know your domain (your solver, your data sources, your review checklist), so it doesn't guess. Name what you need and it creates blank, correctly placed files that tell the team what to write:

| Option | Creates |
|---|---|
| `--skills formulate,run-solver` | `.agents/skills/<name>/SKILL.md` with frontmatter and a step-by-step template |
| `--roles model-checker` | a subagent for each selected agent (`.claude/agents/<name>.md`), read-only by default |
| `--roles "log-triage=fast planner=deep"` | the same, with a model tier (`fast`, `standard`, or `deep`). Without one, a role runs on the caller's model, as the shipped `reviewer` and `test-writer` do. No versioned model name is ever written |
| `--rules "solver=src/solver/** bench=benchmarks/**"` | a path-scoped rule for each selected agent (`.claude/rules/<name>.md`), loaded only for matching paths |
| `--dirs "infra experiments"` | `<dir>/README.md` |

Every `AGENTS.md` also gets a **Project context** section to fill in: domain terms, key libraries, architecture, invariants, gotchas.

### 🧪 The software path

The `devtools` module (the strict tier of every profile but study, or pick it with "pick modules" in the wizard) gives everyone, human or agent, the same verbs:

| Target | Runs |
|---|---|
| `make setup` | install dependencies and dev tools |
| `make lint` / `make fmt` | static checks / reformat |
| `make typecheck` | type checks (skipped if none are configured) |
| `make test` | the **fast tier**: what every change and every PR must pass |
| `make test-all` | the **full tier**: adds slow, regression, and benchmark tests (nightly in CI) |
| `make check` | lint + typecheck + test, the PR bar |

`docs/TESTING.md` lays out the tiers (unit, integration, property-based, regression against golden results, performance) and the rules: determinism, explicit tolerances, golden results reviewed and never regenerated to go green, pinned inputs.

In an empty repo for another stack, the project itself is yours to create (for a Node site, your framework's generator): until its manifest exists, the agent's end-of-turn check and the CI steps wait instead of failing.

In an **empty Python repo** you also get a working uv project (`pyproject.toml`, `src/<package>/`, `tests/`). An existing `Makefile` or `pyproject.toml` is never touched, even with `--force`; CI then calls your own commands. Override any detected command with `--cmd KEY=CMD`.

### 📦 Data and model versioning, local first

The `artifacts` module (ml; research from recommended; anywhere with `--artifacts`):

- keeps `data/` and `models/` out of git (their READMEs stay in);
- records the sha256 of every file in a committed **`artifacts.lock`**, so a commit pins the exact data and models it was built and tested with;
- ships `scripts/artifacts.sh snapshot | verify | status | list | hash` (and `make artifacts-verify` when the Makefile is there); tests that need the real files skip cleanly when they don't match (in CI, for example);
- lets agents verify but not re-pin on their own, and flags PRs that change the lock;
- documents the move to DVC or object storage (and the IaC behind it) in `docs/ARTIFACTS.md`: when remote storage arrives, the lock is the upload list.

## 🔍 The PR gate

Opt-in: add `--actions` (or answer "Yes" in the wizard) at a tier that includes it (`setup.sh list` shows which). Then every PR gets one required check, **PR gate**:

- **Diff guard** checks every PR the same way, whoever or whatever wrote it. Nobody has to declare or sign agent work. It flags deleted or skipped tests, removed assertions, protected-path edits, oversized diffs, new dependencies, large files, re-pinned artifacts, notebooks with outputs, and prompt changes without eval changes.
- **AI review** (strict tier, or add the `review` module; needs `ANTHROPIC_API_KEY`): a fresh Claude Code instance (`claude -p`, read-only tools) reviews each changed file, then does one cross-file pass. It runs in CI whichever coding agents your team uses; other review backends are on the [roadmap](docs/ROADMAP.md).
  - Findings follow a JSON schema and your team's `scripts/ci/review/criteria.md`: categories to report or skip, severity definitions, and examples.
  - Findings are posted inline; low-confidence ones go to "needs a human look".
  - Every finding is fingerprinted, so later runs report only what's new.
- **Gate:** blocking findings fail the check. A maintainer can add `gate-override` to accept the risk, and the override is recorded. A sticky **scorecard** shows every signal and a transparent score.
- **Weekly digest:** PR volume, merge rate and reverts; gate scores, findings, and overrides; AI-review findings by pattern with 👎 dismissal counts, which show which criteria need sharpening.

Plus a stack-aware `ci.yml` (fast tier on every PR), a nightly full-tier workflow, and an eval workflow for agentic repos. The strict tier adds CodeQL and dependency review (both skip private repositories unless you set the `ADVANCED_SECURITY` repository variable to `true`, since they need GitHub Advanced Security there), Dependabot, and `@claude` mentions (when Claude Code is selected). Make **CI** and **PR gate / gate** required in branch protection.

<details>
<summary><b>How the gate is hardened against the PR it judges</b></summary>

- Every job runs its scripts and review criteria from the **base branch**.
- Only this workflow's own bot comments are trusted as earlier scorecards.
- A title or label edit can't cancel a running review, and a commit without a finished review waits instead of passing.
- The reviewing model never sees GitHub tokens, and the diff is fenced off as untrusted data.
- Secret-shaped strings are redacted before posting.
- The PR author (or a bot) can't apply their own override.

Protect `.github/` with CODEOWNERS. With the AI review, pin `CLAUDE_CODE_VERSION` in `pr-gate.yml` to a version you have tested.

</details>

## 🛡️ Guard levels

| | relaxed | standard | strict |
|---|:-:|:-:|:-:|
| Block `rm -rf` of `/` or `~`; block pushes to the default branch, named or implied by being on it (not in solo study repos) | ✅ | ✅ | ✅ |
| Block edits to `.env*` and key files; deny reading secrets | ✅ | ✅ | ✅ |
| Block force-push, `--no-verify`, `curl \| sh`, `chmod 777`, shell access to `.env` | | ✅ | ✅ |
| Lint and typecheck must pass before the agent finishes (Stop hook); it fixes what its change caused and reports failures that were already there | | ✅ | ✅ |
| Block `--force-with-lease`, `reset --hard`, `git clean -f`, `gh pr merge` | | | ✅ |
| CI workflows, CODEOWNERS, `.claude/settings.json`, and hooks are human-only | | | ✅ |
| `git push` asks for confirmation; diff-guard findings fail the gate | | | ✅ |

Rules that must always hold are hooks and gates; `AGENTS.md` only guides. Every block is logged and explained to the agent:

> Blocked by guardrail: force-push rewrites shared history. If this is genuinely required, stop and ask a human to do it.

## 📈 Monitoring

1. **Live usage** (`telemetry`): Claude Code OpenTelemetry metrics (cost, tokens, sessions, tool decisions) sent to your collector.
2. **Local audit** (`audit`): `.agents/logs/events.jsonl` (git-ignored) records each tool call, blocked action, and failed check; `.agents/scripts/agent-report.sh --days 7` summarises it.
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
| `--local-only` | keep everything written out of git on this machine (see the FAQ) |
| `--profile NAME` | `software` · `ml` · `agentic` · `study` · `research` |
| `--tier NAME` | `minimal` · `recommended` · `strict` |
| `--stack NAME` | `node` · `python` · `go` · `rust` · `generic` (default: detected) |
| `--modules LIST` | comma-separated modules, overriding the tier |
| `--guard LEVEL` | `relaxed` · `standard` · `strict` |
| `--agents LIST` | coding agents to set up, comma-separated: `claude`, `codex`, `copilot` (default: `claude`) |
| `--owners LIST` | CODEOWNERS entries, e.g. `"@acme/platform"` |
| `--otel URL` | OTLP endpoint; enables telemetry |
| `--actions` / `--no-actions` | the tier's GitHub Actions workflows on or off (default: off) |
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
<summary><b>Which coding agents does it support?</b></summary>

Claude Code, OpenAI Codex CLI, and GitHub Copilot today. Pick any combination; a mixed team shares one `AGENTS.md`, one set of skills, and one set of guard scripts. See [Coding agents](#-coding-agents) for what each gets.

Cursor and Gemini CLI read `AGENTS.md` and `.agents/skills/` (Gemini after a one-line setting), so they already get the project context and the skills. Their adapters (hooks, permissions, subagents) are planned; [docs/design/providers.md](docs/design/providers.md) has the order. CI checks and the PR gate apply to every PR whichever tool wrote it.

</details>

<details>
<summary><b>Can I use it on a repo without committing anything?</b></summary>

Yes: `--local-only`, or press `l` on the wizard's last screen. Everything is written as usual, then listed in `.git/info/exclude`, git's per-machine ignore file, which is never committed or shared. Nothing new shows up in `git status`, the repository's own `.gitignore` is not touched, and your agents use the setup as normal. (With `--force`, a file git already tracks is overwritten like any other and shows as modified: tracked files cannot be ignored.)

Useful for trying it out, or for using it on a repository whose team has not adopted it. What it cannot do: CI workflows only run once committed, and anything read from the default branch (such as Copilot's cloud agent) will not see it. Files that git already tracks cannot be ignored and are reported. Some agents skip ignored files when they search your code; they still load their own configuration.

To share the setup later, delete the marked block in `.git/info/exclude` and commit.

</details>

<details>
<summary><b>Does it work on Windows?</b></summary>

Yes, with bash. The tool and the hooks it installs are bash scripts, so Windows needs Git Bash (part of [Git for Windows](https://gitforwindows.org/)) or WSL. Run the setup from either one. In the repo it produces:

- **Claude Code** on Windows already requires Git for Windows and runs the hooks through its bash.
- **GitHub Copilot and Codex** run the hooks only when bash is available, so use them from Git Bash or WSL. Started from plain PowerShell, the guardrail hooks may not run.
- **The PR gate and CI** run on GitHub's Linux runners, so they apply whatever OS people use.
- `.claude/skills` is a symbolic link to `.agents/skills`. Windows collaborators need symlinks enabled in git (`git config --global core.symlinks true`, with Developer Mode on) before cloning, or Claude Code will not find the skills. The setup makes a real link even in Git Bash, which copies by default. If Windows does not allow links, it stops before writing anything and says how to turn them on.
- `.gitattributes` rules keep the generated hook and CI scripts on LF line endings, so Windows checkouts, which use CRLF by default, can still run them. Your own scripts are left as they are.

CI runs the test suite on Windows in Git Bash.

</details>

<details>
<summary><b>My company blocks public GitHub. Can I still use it?</b></summary>

Yes. Fork or import the repo into your company's GitHub, through whatever route your security team approves, and clone that. Only people bootstrapping repos ever need access. Generated repos never reference powerharnessing11k or your fork, so nothing breaks when either moves.

</details>

<details>
<summary><b>Why bash?</b></summary>

So it runs anywhere with nothing to install: stock macOS bash 3.2, `git`, `awk`, and `sed`. CI tests it on Linux, on macOS with `/bin/bash`, and on Windows in Git Bash. See [ADR 0001](docs/adr/0001-zero-dependency-shell-cli.md).

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

bash 3.2+ (stock macOS works; on Windows, Git Bash or WSL), git, awk, and sed. `jq` is optional for hooks, which fall back to python3 and then sed. The generated CI uses the `jq` and `gh` preinstalled on GitHub runners; the AI review needs an `ANTHROPIC_API_KEY` secret.

## 🧑‍💻 Development

```sh
make lint   # shellcheck
make test   # tests/run.sh: every profile × tier, the wizard (via a pseudo-terminal), create-only and --force,
            # stubs, artifacts, devtools, hooks, review + gate (with a stubbed claude)
```

`tests/run.sh "guard local_only"` runs only the tests whose names contain one of the given words. CI runs the suite on Linux and on macOS with bash 3.2. Windows (Git Bash) runs a smoke set on PRs, since starting processes is slow there, and the full suite on `main`, nightly, and on demand.

`HARNESS_TEST_UV=1 make test` also runs `make setup && make check` inside a generated Python project (needs uv and network access).

Start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to add a module or profile. [docs/CCAR-ALIGNMENT.md](docs/CCAR-ALIGNMENT.md) explains the practices behind it, [docs/adr/](docs/adr/) the key decisions, and [docs/ROADMAP.md](docs/ROADMAP.md) what's next. This repo uses a harness itself, bootstrapped once and maintained by hand.

## 🙏 Acknowledgements

- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) by Roman Perepelitsa, for showing how good a one-time configuration wizard can feel.
- Anthropic's [Claude Code](https://docs.anthropic.com/en/docs/claude-code) documentation and the Claude Certified Architect exam guides, for the practices.

## 📄 License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). You can use, modify, and redistribute powerharnessing11k, including privately inside a company, as long as you keep the license and notices.

**The files it generates into your repository are yours.** `NOTICE` grants an additional permission to use them however you like, with no attribution required.
