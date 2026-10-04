# harness

**A repeatable agentic harness for any git repository.** Think `p10k configure`, but instead of a zsh prompt it sets up everything a team needs to work safely with coding agents: agent context, guardrail hooks, CI, review automation, and monitoring of what agents actually do.

**The tech lead runs it once; everyone else just pulls.** harness writes self-contained files into the project repo: plain-bash hooks, settings, workflows, and docs. Collaborators install nothing. They clone the project as usual, and Claude Code and GitHub Actions pick everything up.

```sh
# Tech lead, once per project (no install needed):
git clone https://github.com/reclan-ai/harness-workflow /tmp/harness
/tmp/harness/bin/harness configure -C ~/work/my-project
cd ~/work/my-project && git checkout -b chore/agent-harness && git add -A && git commit -m "chore: set up agent harness"
# open a PR; once merged, every collaborator has the harness on their next pull
```

```
   _
  | |__   __ _ _ __ _ __   ___  ___ ___
  | '_ \ / _` | '__| '_ \ / _ \/ __/ __|
  | | | | (_| | |  | | | |  __/\__ \__ \
  |_| |_|\__,_|_|  |_| |_|\___||___/___/

  [1/8]  What is this repository for?

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

Eight single-key questions: profile, stack (auto-detected), commands, which agents, how much harness (minimal / recommended / strict / custom), code owners, telemetry, and confirm. Answers are saved in the project at `.harness/config`, so the setup is **reproducible**. Any maintainer can later re-apply it with `harness update`, for example after changing the config or to pick up a newer harness, and it never clobbers files the team has edited.

## Who does what

| | Tech lead / maintainer | Collaborators |
|---|---|---|
| Install harness | No: run `bin/harness` from any clone | **No** |
| Set up the project | `harness configure`, then commit and open a PR | Pull, as with any change |
| Day to day | Nothing | Nothing. Hooks, permissions, and skills run automatically in Claude Code |
| Change a guardrail or permission | Edit `.harness/config` or `.harness/permissions`, run `harness update`, commit | Propose it in a PR or issue (see the generated `.harness/README.md`) |
| See local agent activity | `.harness/report.sh` | `.harness/report.sh` |
| Upgrade the harness | `git pull` the harness clone, run `harness update`, commit | Pull |

Inside the project, `.harness/README.md` explains all of this to collaborators, so nobody needs to read this page.

## Why

Every team adopting coding agents rebuilds the same scaffolding by hand, and often skips the parts that matter most:

- **Context:** a `CLAUDE.md`/`AGENTS.md` that tells agents how this repo works and what they must never do.
- **Guardrails:** mechanical enforcement through hooks and permissions, not just a polite paragraph.
- **Collaboration:** PR and issue templates that make agent work reviewable, plus CODEOWNERS on the files that control agents.
- **CI/CD:** lint, test, and security checks that apply to humans and agents alike.
- **Monitoring:** what agents did, what got blocked, and whether their PRs were merged, reverted, or flagged.

harness packages all of this as modules, and the defaults are opinionated defaults a tech lead would sign off on.

## Profiles

A **profile** says what the repo is for; a **tier** (minimal / recommended / strict) says how much harness. The profile changes the agent's working agreement in `CLAUDE.md`, adds its own skills, seed files, and guardrails, and picks sensible default modules.

| Profile | Agent working agreement | Skills | Seeded files | Extra guardrails and checks | Recommended modules |
|---|---|---|---|---|---|
| **software** | PR workflow, tests are the contract, scope, deps | `steward`, `task-intake`, `reviewer`, `test-writer` | n/a | n/a | core guardrails quality audit skills collab ci security agent-guard |
| **ml** | + immutable raw data, no data/models in git, seeds and configs, no leakage, baselines, ask before expensive runs | + `experiment`, `data-audit` | `EXPERIMENTS.md`, `docs/DATA.md`, `data/README.md` | `data/raw/` read-only; data/model artifacts git-ignored; CI flags notebooks with outputs and files > 5 MB | software's + `ml` |
| **agentic** | + prompts as code, evals gate changes, model config, untrusted tool output, least-privilege tools, budgets | + `prompt-change`, `agent-tool` | `prompts/`, `evals/` (with example cases) | `evals.yml` runs `EVAL_CMD` on prompt/agent PRs; CI flags prompt changes without eval changes | software's + `agentic` |
| **study** | Tutor, not ghostwriter: diagnose, hints before answers, check understanding, keep the progress log | `tutor`, `quiz`, `study-plan` | `LEARNING_PLAN.md`, `PROGRESS.md`, `notes/`, `exercises/` | Claude Code **Learning** output style; `exercises/` is read-only for agents; solo repo, so pushing to `main` is allowed | core guardrails audit study (guard: relaxed) |
| **research** | Never fabricate citations or results, separate evidence from inference, lab notebook, reproducible analyses | `lab-notebook`, `lit-review`, `claim-check` | `RESEARCH_LOG.md`, `references.bib`, `literature/` | `data/raw/` read-only; `WebSearch` pre-approved; CI flags notebooks with outputs | core guardrails quality audit research collab ci |

`harness list` prints every profile and tier with its exact module list. `EVAL_CMD` (ml, agentic) is asked for in the commands step.

## What gets installed

| Module | Files | What it does |
|---|---|---|
| `core` | `CLAUDE.md` (+ `AGENTS.md`), `.claude/settings.json`, `session-start.sh`, `.gitignore` block | Agent working agreement, permissions, dependency install in cloud sessions |
| `guardrails` | `guard-bash.sh`, `guard-paths.sh` | Block force-push, `--no-verify`, `rm -rf ~`, `curl \| sh`, secret access, pushes to the default branch |
| `quality` | `format-on-edit.sh`, `stop-checks.sh` | Auto-format edited files; run lint/typecheck before the agent says "done" |
| `audit` | `audit-log.sh`, `.harness/report.sh` | Local JSONL trail of agent tool use and blocked actions, summarised by `.harness/report.sh` |
| `skills` | `.claude/skills/{steward,task-intake}`, `.claude/agents/{reviewer,test-writer}` | Repo workflows for driving PRs to green and starting tasks well |
| `collab` | `CONTRIBUTING.md`, `CODEOWNERS`, PR template, issue templates (incl. **Agent task**), `docs/agents/HANDBOOK.md` | How humans and agents collaborate |
| `ci` | `ci.yml`, `pr-title.yml` | Stack-aware CI; Conventional Commit PR titles |
| `security` | `dependabot.yml`, `codeql.yml`, `dependency-review.yml` | Dependency updates, code scanning, vulnerable-dependency gate |
| `agent-guard` | `agent-guard.yml` + script, `agent-digest.yml` | Detect and label agent PRs; flag deleted/skipped tests, removed assertions, protected-path edits, oversized diffs, new deps; weekly digest issue |
| `review` | `claude.yml`, `claude-review.yml`, `REVIEW.md` | `@claude` on issues/PRs and automatic PR review |
| `telemetry` | settings `env`, `docs/agents/TELEMETRY.md` | Claude Code OpenTelemetry export to your collector |
| `ml` / `agentic` / `study` / `research` | see [Profiles](#profiles) | Profile-specific skills, seed files, and guardrails |

Tiers per profile: **minimal** (core, guardrails, and the profile module; guard relaxed), **recommended** (the profile's defaults above), **strict** (more modules, such as `review`, and a stricter guard level). Telemetry is added whenever you give an OTLP endpoint.

Supported stacks: Node (npm/pnpm/yarn/bun), Python (uv/poetry/pip), Go, Rust, and generic (bring your own commands).

## Guard levels

| | relaxed | standard | strict |
|---|:-:|:-:|:-:|
| Block `rm -rf` of `/` or `~`, pushes to the default branch | ✅ | ✅ | ✅ |
| Block edits to `.env*` and key files; deny reading secrets | ✅ | ✅ | ✅ |
| Block force-push, `--no-verify`, `curl \| sh`, `chmod 777`, shell access to `.env` | | ✅ | ✅ |
| Lint/typecheck must pass before the agent finishes (Stop hook) | | ✅ | ✅ |
| Block `--force-with-lease`, `reset --hard`, `git clean -f`, `gh pr merge` | | | ✅ |
| CI workflows, CODEOWNERS, `.claude/settings.json`, hooks, `.harness/` are human-only | | | ✅ |
| `git push` asks for confirmation | | | ✅ |
| Agent-guard findings **fail** the PR (instead of warning) | | | ✅ |

Every blocked action is logged and explained to the agent: *"Blocked by harness guardrail: force-push rewrites shared history. If this is genuinely required, stop and ask a human to do it."*

## Three layers of agent monitoring

1. **Live usage** (`telemetry`): OpenTelemetry metrics from Claude Code covering cost, tokens, sessions, and tool decisions.
2. **Local audit** (`audit`): `.harness/logs/events.jsonl` records each tool call, blocked action, and failed check. `.harness/report.sh --days 7`, which is committed in the project, summarises it.
3. **Outcomes** (`agent-guard`): every PR is checked in CI. Agent PRs are detected (co-author trailer, branch prefix, or PR checkbox), labelled `agent-authored`, and inspected for the failure modes agents are most prone to. A weekly **Agent digest** issue reports agent PR volume, merge rate, closures, and reverts.

## Commands (maintainers)

Run them from any clone as `/path/to/harness/bin/harness <command>`. Optionally, `install.sh` puts `harness` on your PATH if you manage many repos.

```
harness configure   Run the wizard (re-run any time; previous answers are kept)
harness update      Re-apply from .harness/config, e.g. after editing it or upgrading harness
harness doctor      Check drift, hook permissions, settings validity, tool availability
harness report      Same as the project's .harness/report.sh (--days N)
harness list        Show profiles, tiers, and modules
harness self-update Pull the latest harness (only if installed via install.sh)
```

Non-interactive (CI, scripts, fleet rollout):

```sh
harness configure --yes --profile ml --tier strict --owners @acme/platform --agents multi
harness configure --yes --profile study
harness configure --yes --stack python --modules core,guardrails,ci --guard standard
harness update --dry-run
```

## How updates stay safe

harness owns files in one of four ways (details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)):

- **Managed files** (workflows, hooks, skills) are tracked by sha256 in `.harness/manifest`. They are updated only while they still match what harness wrote. Once you edit one, harness leaves it alone and writes `<file>.harness-new` next to it so you can merge by hand.
- **Managed blocks** (`CLAUDE.md`, `AGENTS.md`, `.gitignore`, `REVIEW.md`): harness owns only the text between the `>>> harness:managed` and `<<< harness:managed` markers. Everything else in the file is yours.
- **Seeds** (`SECURITY.md`, `.editorconfig`, `.harness/permissions`) are written once and never touched again.
- **Your rules** in `.harness/permissions` (`allow|ask|deny <rule>`) are merged into the generated `settings.json` on every update.

Commit everything harness writes, including `.harness/config`, `.harness/manifest`, `.harness/permissions`, `.harness/README.md`, and `.harness/report.sh`. Logs are git-ignored.

## Using harness inside a company

harness is designed to be forked into a company's GitHub org and run from there. Many companies block raw downloads from public GitHub, and they should review outside tools anyway. Only tech leads ever touch the fork; project collaborators never need access to it.

1. **Fork or import** the repo into your org (e.g. `github.com/yourco/harness-workflow`), through whatever route your security team approves.
2. **Run it from the fork:** `git clone <fork> /tmp/harness && /tmp/harness/bin/harness configure -C <project>`. Nothing reaches public GitHub.
3. The fork is your team's release channel. Sync upstream changes into it when you choose to, and pin with a tag (`git checkout v0.1.0`).
4. Generated docs (`CONTRIBUTING.md`, `.harness/README.md`) link to wherever harness was run from (credentials stripped), so projects point at your fork automatically.

## Requirements

bash 3.2+ (stock macOS works), git, awk, sed. `jq` is optional: hooks fall back to python3, then to sed. No Node, no Python, no package install.

## Develop

```sh
make lint   # shellcheck
make test   # tests/run.sh: renders every stack, checks idempotency, conflicts, hooks, agent-guard
```

This repo runs its own harness (see `.harness/config`). Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to add a module, and [docs/ROADMAP.md](docs/ROADMAP.md) for what's next.

## License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). You can use, modify, and redistribute harness, including privately inside a company, as long as you keep the license and notices.

**The files harness generates into your repository are yours.** `NOTICE` grants an additional permission to use, modify, and license generated output however you like, with no attribution required.
