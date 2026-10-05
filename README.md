# harness

**A repeatable agentic harness for any git repository.** Think `p10k configure`, but instead of a zsh prompt it sets up everything a team needs to work well with coding agents: agent context and rules, skills, roles, guardrail hooks, CI with AI review and a quality gate, and monitoring of what agents actually do. The practices follow Anthropic's Claude Certified Architect exam guides ([how](docs/CCAR-ALIGNMENT.md)).

```sh
git clone --depth=1 https://github.com/reclan-ai/harness-workflow ~/.harness-workflow
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

Eight single-key questions: profile, stack (auto-detected), commands, which agents, how much harness (minimal / recommended / strict / custom), code owners, telemetry, and confirm. The answers are saved in the project at `.harness/config`, so the setup is **reproducible**, and re-running never clobbers files the team has edited.

## Who does what

**The tech lead runs harness once; everyone else just pulls.** Everything harness writes is self-contained in the project repo: plain-bash hooks, settings, rules, skills, workflows, and docs.

| | Tech lead / maintainer | Collaborators |
|---|---|---|
| Get harness | `git clone` it once (anywhere) | **Nothing** |
| Set up the project | `setup.sh`, then commit and open a PR | Pull, as with any change |
| Day to day | Nothing | Nothing: Claude Code loads the rules, skills, roles, and hooks automatically |
| Change a guardrail or permission | Edit `.harness/config` or `.harness/permissions`, run `setup.sh update`, commit | Propose it in a PR or issue (see the generated `.harness/README.md`) |
| Upgrade | `git -C ~/.harness-workflow pull`, then `setup.sh update`, commit | Pull |

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

Plus stack-aware `ci.yml`, Conventional Commit PR titles, CodeQL, dependency review, Dependabot, `@claude` mentions, and an eval workflow for agentic repos. Make **CI** and **PR gate / gate** required in branch protection. (Upgrading from an earlier harness? The old "Agent guard" check is now part of the gate: swap the required check.)

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
| CI workflows, CODEOWNERS, `.claude/settings.json`, hooks, `.harness/` are human-only | | | ✅ |
| `git push` asks for confirmation; agent-guard findings fail the gate | | | ✅ |

Rules that must always hold are hooks and gates; `CLAUDE.md` only guides. Every block is logged and explained to the agent: *"Blocked by harness guardrail: force-push rewrites shared history. If this is genuinely required, stop and ask a human to do it."*

## Monitoring

1. **Live usage** (`telemetry`): Claude Code OpenTelemetry metrics (cost, tokens, sessions, tool decisions) sent to your collector.
2. **Local audit** (`audit`): `.harness/logs/events.jsonl` records each tool call, blocked action, and failed check; `.harness/report.sh --days 7` summarises it.
3. **Outcomes** (PR gate): scorecards on every PR and the weekly digest.

## Commands

All through `setup.sh`, run from inside the project:

```
setup.sh                 the wizard (re-run any time; previous answers are kept)
setup.sh update          re-apply .harness/config (after editing it, or after a harness upgrade)
setup.sh doctor          check drift, hook permissions, settings validity, tools
setup.sh report          summarise local agent activity (--days N)
setup.sh list            profiles, tiers, and modules
setup.sh help            all options
```

Non-interactive (scripts, fleet rollout):

```sh
~/.harness-workflow/setup.sh --yes --profile ml --tier strict --owners @acme/platform --agents multi
~/.harness-workflow/setup.sh --yes --profile study
~/.harness-workflow/setup.sh update --dry-run
```

## How updates stay safe

harness owns files in one of four ways (details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)):

- **Managed files** (workflows, hooks, rules, skills, roles) are tracked by sha256 in `.harness/manifest` and updated only while they still match what harness wrote. Once someone edits one, harness leaves it alone and writes `<file>.harness-new` next to it.
- **Managed blocks** (`CLAUDE.md`, `AGENTS.md`, `.gitignore`, `REVIEW.md`): harness owns only the text between the `>>> harness:managed` / `<<< harness:managed` markers.
- **Seeds** (`.github/review/criteria.md`, `.mcp.json`, `SECURITY.md`, logs and plans) are written once and are then the team's.
- **Your rules** in `.harness/permissions` (`allow|ask|deny <rule>`) are merged into `settings.json` on every update.

## Using harness inside a company

Fork or import the repo into your company's GitHub org, through whatever route your security team approves, and clone *that*. Only tech leads ever touch it; collaborators never need access. The fork is your release channel: sync upstream when you choose, and pin with a tag. Generated docs link to wherever harness was cloned from, with credentials stripped.

## Requirements

bash 3.2+ (stock macOS works), git, awk, sed. `jq` is optional for hooks, which fall back to python3 and then sed. CI scripts use the `jq` and `gh` preinstalled on GitHub runners.

## Develop

```sh
make lint   # shellcheck
make test   # tests/run.sh: every profile × tier, idempotency, conflicts, hooks, review + gate (stubbed claude)
```

This repo runs its own harness. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to add a module or profile, [docs/CCAR-ALIGNMENT.md](docs/CCAR-ALIGNMENT.md) for the practices behind it, and [docs/ROADMAP.md](docs/ROADMAP.md) for what's next.

## License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). You can use, modify, and redistribute harness, including privately inside a company, as long as you keep the license and notices. **The files harness generates into your repository are yours**: `NOTICE` grants an additional permission to use them however you like, with no attribution required.
