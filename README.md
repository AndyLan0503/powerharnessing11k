# harness

**A repeatable agentic harness for any git repository.** Think `p10k configure`, but instead of a zsh prompt it sets up everything a team needs to work safely with coding agents: agent context, guardrail hooks, CI, review automation, and monitoring of what agents actually do.

```sh
git clone https://github.com/reclan-ai/harness-workflow ~/.harness-workflow
~/.harness-workflow/install.sh
cd your-repo
harness configure
```

(If your network allows raw downloads, `curl -fsSL https://raw.githubusercontent.com/reclan-ai/harness-workflow/main/install.sh | bash` does the same in one step.)

```
   _
  | |__   __ _ _ __ _ __   ___  ___ ___
  | '_ \ / _` | '__| '_ \ / _ \/ __/ __|
  | | | | (_| | |  | | | |  __/\__ \__ \
  |_| |_|\__,_|_|  |_| |_|\___||___/___/

  [4/7]  How much harness do you want?

  (1)  Minimal
       Guardrails only: agent context + hooks that block destructive actions.

  (2)  Standard (recommended)
       Recommended for teams: guardrails, quality hooks, collaboration files, CI, ...

  (3)  Strict
       For regulated or high-stakes repos: everything in standard, plus Claude PR review, ...

  (4)  Custom
       Pick modules and guard level one by one

  (r)  Restart from the beginning.
  (q)  Quit and do nothing.
```

Seven single-key questions: stack (auto-detected), commands, which agents, preset, code owners, telemetry, and confirm. Answers are saved to `.harness/config`, so the setup is **reproducible**. Re-run `harness update` whenever you change the config or upgrade harness, and it never clobbers files your team has edited.

## Why

Every team adopting coding agents rebuilds the same scaffolding by hand, and often skips the parts that matter most:

- **Context:** a `CLAUDE.md`/`AGENTS.md` that tells agents how this repo works and what they must never do.
- **Guardrails:** mechanical enforcement through hooks and permissions, not just a polite paragraph.
- **Collaboration:** PR and issue templates that make agent work reviewable, plus CODEOWNERS on the files that control agents.
- **CI/CD:** lint, test, and security checks that apply to humans and agents alike.
- **Monitoring:** what agents did, what got blocked, and whether their PRs were merged, reverted, or flagged.

harness packages all of this as modules, and the defaults are opinionated defaults a tech lead would sign off on.

## What gets installed

| Module | Files | What it does |
|---|---|---|
| `core` | `CLAUDE.md` (+ `AGENTS.md`), `.claude/settings.json`, `session-start.sh`, `.gitignore` block | Agent working agreement, permissions, dependency install in cloud sessions |
| `guardrails` | `guard-bash.sh`, `guard-paths.sh` | Block force-push, `--no-verify`, `rm -rf ~`, `curl \| sh`, secret access, pushes to the default branch |
| `quality` | `format-on-edit.sh`, `stop-checks.sh` | Auto-format edited files; run lint/typecheck before the agent says "done" |
| `audit` | `audit-log.sh` | Local JSONL trail of agent tool use and blocked actions → `harness report` |
| `skills` | `.claude/skills/{steward,task-intake}`, `.claude/agents/{reviewer,test-writer}` | Repo workflows for driving PRs to green and starting tasks well |
| `collab` | `CONTRIBUTING.md`, `CODEOWNERS`, PR template, issue templates (incl. **Agent task**), `docs/agents/HANDBOOK.md` | How humans and agents collaborate |
| `ci` | `ci.yml`, `pr-title.yml` | Stack-aware CI; Conventional Commit PR titles |
| `security` | `dependabot.yml`, `codeql.yml`, `dependency-review.yml` | Dependency updates, code scanning, vulnerable-dependency gate |
| `agent-guard` | `agent-guard.yml` + script, `agent-digest.yml` | Detect and label agent PRs; flag deleted/skipped tests, removed assertions, protected-path edits, oversized diffs, new deps; weekly digest issue |
| `review` | `claude.yml`, `claude-review.yml`, `REVIEW.md` | `@claude` on issues/PRs and automatic PR review |
| `telemetry` | settings `env`, `docs/agents/TELEMETRY.md` | Claude Code OpenTelemetry export to your collector |

Presets: **minimal** (`core guardrails`), **standard** (everything except `review` and `telemetry`), **strict** (standard + `review`, strict guard level). Telemetry is added whenever you give an OTLP endpoint.

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
2. **Local audit** (`audit`): `.harness/logs/events.jsonl` records each tool call, blocked action, and failed check. `harness report --days 7` summarises it.
3. **Outcomes** (`agent-guard`): every PR is checked in CI. Agent PRs are detected (co-author trailer, branch prefix, or PR checkbox), labelled `agent-authored`, and inspected for the failure modes agents are most prone to. A weekly **Agent digest** issue reports agent PR volume, merge rate, closures, and reverts.

## Commands

```
harness configure   Run the wizard (re-run any time; previous answers are kept)
harness update      Re-apply from .harness/config, e.g. after editing it or upgrading harness
harness doctor      Check drift, hook permissions, settings validity, tool availability
harness report      Summarise the local agent audit log (--days N)
harness list        Show modules and presets
harness self-update Pull the latest harness
```

Non-interactive (CI, scripts, fleet rollout):

```sh
harness configure --yes --preset strict --owners @acme/platform --agents multi
harness configure --yes --stack python --modules core,guardrails,ci --guard standard
harness update --dry-run
```

## How updates stay safe

harness owns files in one of four ways (details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)):

- **Managed files** (workflows, hooks, skills) are tracked by sha256 in `.harness/manifest`. They are updated only while they still match what harness wrote. Once you edit one, harness leaves it alone and writes `<file>.harness-new` next to it so you can merge by hand.
- **Managed blocks** (`CLAUDE.md`, `AGENTS.md`, `.gitignore`, `REVIEW.md`): harness owns only the text between the `>>> harness:managed` and `<<< harness:managed` markers. Everything else in the file is yours.
- **Seeds** (`SECURITY.md`, `.editorconfig`, `.harness/permissions`) are written once and never touched again.
- **Your rules** in `.harness/permissions` (`allow|ask|deny <rule>`) are merged into the generated `settings.json` on every update.

Commit `.harness/config`, `.harness/manifest`, and `.harness/permissions`. Logs are git-ignored.

## Using harness inside a company

harness is designed to be forked into a company's GitHub org and run from there. Many companies block raw downloads from public GitHub, and they should review outside tools anyway.

1. **Fork or import** the repo into your org (e.g. `github.com/yourco/harness-workflow`), through whatever route your security team approves.
2. **Install from the fork:** clone it and run `install.sh` from the clone, or set `HARNESS_REPO=<fork url>`. Nothing reaches public GitHub.
3. `harness self-update` pulls from the fork's `origin`, so the fork is the team's release channel. Sync upstream changes into it when you choose to.
4. Generated `CONTRIBUTING.md` files link to wherever harness was installed from (credentials stripped), so your repos point at your fork automatically.
5. Pin a release by installing a tag: `HARNESS_REF=v0.1.0`.

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
