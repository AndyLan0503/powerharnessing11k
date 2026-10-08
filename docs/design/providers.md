# Design: provider support

Status: accepted. Build in progress; see section 9.
Decision record: [ADR 0005](../adr/0005-provider-adapters.md).
Research date: 2026-10-05, from each vendor's official documentation.

## 1. Goal

Today the tool assumes three vendors: Claude Code as the coding agent, GitHub as the git host, and the Anthropic API behind the AI review. The goal is to let the person bootstrapping a repo choose each of these, and to get the matching setup for every choice.

Agreed with the maintainer before this design:

- All three kinds of provider are in scope: coding agent, AI review backend, git host.
- The wizard lists common providers and the user selects which ones the team uses.
- Support is best effort per provider: each one gets what it natively supports, and the wizard says plainly what is missing.
- This ships as new PRs after PR #2, design first.

## 2. The three choices

| Choice | Options in the first release | How many | Flag |
|---|---|---|---|
| Coding agents | Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot, Gemini CLI | one or more | `--agents claude,codex,cursor,copilot,gemini` |
| Git host | GitHub, GitLab, none | exactly one | `--host github\|gitlab\|none` |
| AI review backend | Claude (Anthropic API, AWS Bedrock, Google Vertex), Codex, Gemini, Copilot | one, only when the review module is on | `--review-backend NAME` |

A team can use several coding agents at once, so that choice is multi-select. A repository lives on one host and one review backend keeps findings comparable from PR to PR, so those are single-select.

`--host none` covers repos with no CI at all: the tool then writes only the local harness.

The current `--agents claude|multi` values go away. This tool runs once per repo and keeps no state, so there is nothing to migrate.

## 3. Principle: write shared content once, adapt per provider

Every module today writes Claude-shaped files directly (`.claude/rules/x.md`, `.claude/skills/x/SKILL.md`). The refactor makes modules describe *what* they contribute in neutral terms, and gives each provider an adapter that decides *where and in what format* it lands.

```
modules/<name>/module.sh        says: here is a rule, a skill, a role, a guard hook,
                                an allowed command, a CI job
        |
        v
neutral emitters (lib/)         emit_rule, emit_skill, emit_role, settings_allow,
                                settings_deny, settings_hook, emit_ci_job
        |
        +--> agents/<agent>/adapter.sh     one per selected coding agent
        +--> hosts/<host>/adapter.sh       the selected git host
        +--> reviewers/<backend>/adapter.sh the selected review backend
```

`settings_allow`, `settings_deny`, and `settings_hook` already exist and are already neutral in shape. The work is to add `emit_rule`, `emit_skill`, and `emit_role`, and to move the format knowledge out of the modules.

Adding a provider later means adding one adapter directory and its tests. No module changes.

## 4. Coding agents

### 4.1 What each agent can be given

Facts from the vendors' documentation. "none" means the agent has no committed, project-level way to do it.

| Layer | Claude Code | Codex CLI | Cursor | GitHub Copilot | Gemini CLI |
|---|---|---|---|---|---|
| Instructions | `.claude/CLAUDE.md` (imports `@../AGENTS.md`) | `AGENTS.md` | `AGENTS.md` | `AGENTS.md`, `.github/copilot-instructions.md` | `GEMINI.md`; `AGENTS.md` once listed in `.gemini/settings.json` |
| Path-scoped rules | `.claude/rules/*.md`, `paths:` | none (nested `AGENTS.md` only) | `.cursor/rules/*.mdc`, `globs:` | `.github/instructions/*.instructions.md`, `applyTo:` | none (nested context files only) |
| Skills | `.claude/skills/` | `.agents/skills/` | `.agents/skills/`, also `.claude/skills/` | `.agents/skills/`, also `.claude/skills/` | `.agents/skills/` |
| Subagents | `.claude/agents/*.md`, tool list | `.codex/agents/*.toml`, sandbox mode | `.cursor/agents/*.md`, `readonly` flag | `.github/agents/*.agent.md`, tool list | `.gemini/agents/*.md`, tool list |
| Command permissions | `.claude/settings.json` | `.codex/config.toml` plus `.codex/rules/*.rules` | `.cursor/cli.json` | none verified at project level | `.gemini/settings.json` (`tools.allowed`, `tools.exclude`) |
| Hooks that can block | yes, exit 2 | yes, exit 2 | yes, exit 2 or JSON | yes, JSON or non-zero exit | yes, exit 2 or JSON |
| Hook config | `.claude/settings.json` | `.codex/hooks.json` | `.cursor/hooks.json` | `.github/hooks/*.json` | `.gemini/settings.json` |
| MCP servers | `.mcp.json` | `.codex/config.toml` | `.cursor/mcp.json` | `.mcp.json` (CLI) | `.gemini/settings.json` |

Two things make this tractable. All five agents now have blocking hooks with a JSON payload on stdin, and four of the five read the same `.agents/skills/` folder.

### 4.2 Mapping

**Instructions.** `AGENTS.md` becomes the single source of project context, working agreement, and commands, for every repo. Claude Code gets a three-line `CLAUDE.md` that imports it. Gemini gets a settings entry that makes it read `AGENTS.md`. Copilot, Codex, and Cursor read it natively. This removes today's two modes (everything in `CLAUDE.md`, or split with `AGENTS.md`), which also simplifies the templates.

**Path-scoped rules.** Each rule has one body and a list of globs. The adapter adds the right frontmatter and path: `paths:` for Claude, `globs:` for Cursor, `applyTo:` for Copilot. Codex and Gemini have no path scoping, so for them each rule is appended to `AGENTS.md` under a heading that names the paths it applies to. That costs always-loaded context for those two agents, which the wizard reports.

**Skills.** One copy in `.agents/skills/<name>/SKILL.md`, which Codex, Cursor, Copilot, and Gemini read. Claude Code reads only `.claude/skills/`, so that path is a symlink to `../.agents/skills`.

**Slash commands.** `/review` and `/handoff` become skills. Skills are the portable form, and Claude Code and Cursor both let a user invoke a skill by name, so nothing is lost.

**Subagents.** One body per role plus an abstract capability (`read-only` or `read-write`). Adapters translate: a tool list for Claude, Copilot, and Gemini; `readonly: true` for Cursor; `sandbox_mode = "read-only"` in TOML for Codex.

**Permissions.** Modules keep calling `settings_allow 'make test'` and `settings_deny` with a neutral command or path. Adapters render: Claude `Bash(make test:*)`, Cursor `Shell(make test)`, Codex a `prefix_rule(pattern=["make","test"], decision="allow")`, Gemini `tools.allowed`. Copilot gets no permission file, because none could be verified; its guard hooks still apply.

**Hooks.** The guard logic (what counts as a destructive command, which paths are protected) stays in one set of scripts, moved to a neutral `.agents/hooks/` folder. Each agent's hook config calls the same script with the agent's name:

```
.agents/hooks/guard-bash.sh claude     <- from .claude/settings.json
.agents/hooks/guard-bash.sh codex      <- from .codex/hooks.json
.agents/hooks/guard-bash.sh cursor     <- from .cursor/hooks.json
```

`lib.sh` already isolates "read a field from the payload" and "block with a reason". It gains a small per-agent table: which field holds the command, which holds the file path, and how to signal a block (exit 2 for Claude, Codex, Cursor, and Gemini; a JSON `permissionDecision` on stdout for Copilot).

| Hook | Claude | Codex | Cursor | Copilot | Gemini |
|---|---|---|---|---|---|
| Guard shell commands | PreToolUse | PreToolUse | beforeShellExecution | preToolUse | BeforeTool |
| Guard file edits | PreToolUse | PreToolUse | preToolUse | preToolUse | BeforeTool |
| Format after edit | PostToolUse | PostToolUse | afterFileEdit | postToolUse | AfterTool |
| Lint before finishing | Stop | Stop | stop | agentStop | AfterAgent |
| Audit log | PostToolUse, Stop | same | same | same | same |
| Session start | SessionStart | SessionStart | sessionStart | sessionStart | SessionStart |

### 4.3 Known gaps, reported to the user

The wizard's final screen and the generated handbook get a coverage table built from the adapters, so it cannot drift from what was written. Expected content:

| | Claude | Codex | Cursor | Copilot | Gemini |
|---|:-:|:-:|:-:|:-:|:-:|
| Shared instructions | yes | yes | yes | yes | yes |
| Rules load only for matching paths | yes | always loaded | yes | yes | always loaded |
| Skills | yes | yes | yes | yes | yes |
| Subagents with limited tools | yes | sandbox level only | read-only flag only | yes | yes |
| Pre-approved and denied commands | yes | yes | CLI only | hooks only | yes |
| Guard hooks | yes | yes | yes | yes | yes |
| Lint must pass before finishing | yes | yes | to verify | to verify | to verify |

### 4.4 To verify with the real tools during the build

The research flagged these as not confirmed from documentation. Each gets a contract test against the real CLI before its adapter ships.

- Claude Code: confirm it still reads skills from `.claude/skills/` only, since the symlink in decision 1 depends on it.
- Gemini and Copilot: the exact payload field that carries the shell command.
- Cursor, Copilot, Gemini: whether a stop-type hook can send the agent back to work, as Claude's and Codex's can.
- Codex (adapter shipped): hook payloads, the `stop_hook_active` flag, matchers, timeouts, config keys, the rules syntax, and the subagent format were checked against the Codex source and docs. Still open: whether a project-level `[permissions.*]` profile can deny file reads (so the adapter writes none), and a run against a signed-in Codex CLI, which no test here performs.
- Copilot: whether `.github/copilot/settings.json` accepts permission rules.
- Codex loads `.codex/config.toml` only for trusted projects. The next-steps text must say so.

## 5. Git host

### 5.1 Structure

The CI logic is already mostly plain bash: `diff-guard.sh`, `pr-gate.sh`, and `ai-review.sh` take SHAs and environment variables. What is host-specific is the pipeline YAML and a handful of API calls (post or update the scorecard comment, post inline comments, read labels and who added one, write a job summary, pass values between jobs).

Those calls move behind a small host library with one implementation per host:

| Function | GitHub | GitLab |
|---|---|---|
| `host_comment_upsert` | `gh api` issue comments | Notes API, found by a hidden marker |
| `host_inline_comments` | review with comments | Discussions API with a position |
| `host_labels`, `host_label_actor` | event payload, issue events | `CI_MERGE_REQUEST_LABELS`, resource label events |
| `host_summary` | `$GITHUB_STEP_SUMMARY` | job log (no equivalent exists) |
| `host_output` | `$GITHUB_OUTPUT` | dotenv report artifact |

The scripts move from `.github/scripts/` to a neutral `scripts/ci/` so both hosts use the same files.

### 5.2 GitHub to GitLab mapping

| Piece | GitHub today | GitLab |
|---|---|---|
| Pipelines | `.github/workflows/*.yml` | `.gitlab-ci.yml` including `.gitlab/ci/*.yml`, with merge-request `workflow:rules` |
| Required check | branch protection, required checks | "Pipelines must succeed" (Free) |
| Fast tests on every change | `ci.yml` | `ci.yml` jobs |
| Nightly full tests, weekly digest | `schedule:` in the workflow | jobs with `rules: $CI_PIPELINE_SOURCE == "schedule"`; the schedule itself is created in the UI or API |
| PR title check | `pr-title.yml` | a job testing `$CI_MERGE_REQUEST_TITLE` |
| PR and issue templates | `.github/` templates and issue forms | `.gitlab/merge_request_templates/Default.md`, `.gitlab/issue_templates/*.md` |
| Code owners | `.github/CODEOWNERS` | `.gitlab/CODEOWNERS` with a section |
| Code scanning | CodeQL | SAST template |
| Secret scanning | repository setting | Secret Detection template |
| Dependency review and updates | dependency review, Dependabot | no Free equivalent; see gaps |
| Protected-path guard | `guard-bash` blocks `gh pr merge` | also blocks `glab mr merge` |

### 5.3 GitLab gaps, reported to the user

These follow from GitLab's design or its pricing tiers. The baseline targets the Free tier.

- **Scorecard and inline review comments need a token.** The built-in job token cannot write to merge requests. With a `GITLAB_TOKEN` CI variable the gate comments as on GitHub. Without one, the gate still passes or fails and prints the scorecard in the job log.
- **An MR can edit the pipeline that judges it.** Scripts are read from the target branch, as on GitHub, but `.gitlab-ci.yml` itself comes from the MR. Closing this needs pipeline execution policies (Ultimate) or a separate config project. The handbook explains both.
- **Schedules cannot be committed.** Next steps print the exact commands to create the nightly and weekly schedules.
- **Code-owner enforcement and required approvals are Premium.** The `CODEOWNERS` file is written either way.
- **No dependency review or Dependabot equivalent on Free.** Dependency Scanning is Ultimate. The handbook points to Renovate as the usual substitute.
- **Override label.** Label changes may not retrigger a pipeline, so after adding `gate-override` a maintainer re-runs the gate job.
- **No issue forms.** The agent-task template becomes a Markdown template.

## 6. AI review backend

`ai-review.sh` has one vendor-specific step: run a model on a prompt, read-only, and get findings as JSON that match the schema. That step becomes one function with an implementation per backend. Everything around it (splitting the diff per file, the cross-file pass, fingerprints, redaction, posting) is unchanged.

| Backend | Command | Structured output | Read-only | Credentials |
|---|---|---|---|---|
| Claude, Anthropic API | `claude -p --output-format json --json-schema` | enforced by the CLI | `--tools "Read,Glob,Grep"` | `ANTHROPIC_API_KEY` |
| Claude, AWS Bedrock | same, `CLAUDE_CODE_USE_BEDROCK=1` | enforced | same | OIDC role, no stored key |
| Claude, Google Vertex | same, `CLAUDE_CODE_USE_VERTEX=1` | enforced | same | workload identity, no stored key |
| Codex | `codex exec - --output-schema schema.json -o out.json` | enforced by the CLI | `--sandbox read-only` | `CODEX_API_KEY` |
| Gemini | `gemini -p --output-format json` | none; schema goes in the prompt | `--approval-mode plan` | `GEMINI_API_KEY` |
| Copilot | `copilot -p -s --no-ask-user` | none; schema goes in the prompt | `--deny-tool` list | `COPILOT_GITHUB_TOKEN` |

Design points:

- **One validation path for all backends.** Output from every backend is checked against the findings shape with `jq` before use, with one retry. Two backends cannot enforce a schema, and the script already distrusts model output.
- **Bedrock and Vertex need a pinned model.** With none set they default to the most expensive model. The generated workflow fails early with a clear message until a model variable is set.
- **Keyless cloud auth.** Bedrock and Vertex use the host's OIDC token (GitHub `id-token: write`, GitLab `id_tokens`), so no long-lived cloud key is stored.
- **Gaps to report:** Gemini and Copilot have weaker output guarantees, and their read-only modes are less strict than Claude's or Codex's. The review job runs with a read-only token on both hosts regardless.
- **Later option:** a plain HTTP backend (curl to a chat-completions endpoint) for teams that cannot install a CLI. It reviews the diff only, without reading the rest of the repo, so it is left out of the first release.

## 7. Wizard

Two new screens and one changed screen. The wizard goes from 10 to 12 steps.

- **Which coding agents?** A checklist replacing today's two-option screen. Space toggles, Enter confirms. Claude Code is preselected.
- **Where is the repo hosted?** GitHub, GitLab, or none. Detected from the `origin` remote when there is one.
- **Which model reviews PRs?** Shown only when AI review is on.

The confirm screen and the final summary show the coverage table from 4.3 for the selected agents, plus the host and backend gaps that apply.

## 8. Tests

Each item below is an end-to-end test in `tests/run.sh`, run on Linux and on macOS with bash 3.2.

- **Matrix:** every agent on its own, all five together, each host, each backend. Generated JSON, TOML, and YAML must parse. No unrendered placeholders. No reference back to this tool.
- **Hook contracts:** for each agent, a fixture of its documented payload for a force-push and for an edit to `.env` goes through the real generated hook config path. The test asserts the block and the agent-specific block signal. A harmless command must pass.
- **Single source:** with several agents selected, the rule bodies, role bodies, and skills are byte-identical across agents apart from frontmatter.
- **Review backends:** the existing stub-CLI technique, one stub per backend, including a backend that returns malformed JSON and one that returns JSON violating the schema.
- **GitLab gate:** a fake `curl` records API calls. Tests cover the scorecard upsert, the no-token path, the override actor check, and dotenv outputs.
- **Real-CLI smoke tests:** opt-in by environment variable, one per agent, to settle the items in 4.4.

## 9. Delivery

Each PR is releasable on its own.

| # | Scope | Visible change |
|:-:|---|---|
| 1 | Engine: neutral emitters, adapter interface, Claude adapter only. `AGENTS.md` as the source of truth, commands become skills, skills in `.agents/skills/`, hooks in `.agents/hooks/`, CI scripts in `scripts/ci/` | Same protection as today for Claude Code; file layout changes as described |
| 2 | Codex adapter. Multi-select agents screen and coverage table (done) | Codex teams get a harness |
| 3 | Copilot adapter | Copilot teams get a harness |
| 4 | Review backends: Bedrock, Vertex, Codex, Gemini, Copilot | The gate no longer needs an Anthropic API key |
| 5 | Host adapter: GitLab, and `none` | GitLab repos get CI, the gate, and templates |
| 6 | Cursor and Gemini adapters | Later |
| 7 | README, runbook, and handbook rewritten around the three choices | Docs (each PR also updates the docs it touches) |

PR 1 carries the risk, because it moves files every later step depends on. It lands alone, with the full existing suite passing.

## 10. Decisions

Settled with the maintainer on 2026-10-05.

1. **Skills for Claude Code:** `.claude/skills` is a symlink to `../.agents/skills`. One copy. Windows collaborators need `core.symlinks` enabled.
2. **`AGENTS.md` is the source of truth in every repo.** `.claude/CLAUDE.md` contains an `@../AGENTS.md` import and nothing else that matters.
3. **CI scripts live in `scripts/ci/`** on every host.
4. **GitLab baseline is the Free tier.** Premium and Ultimate improvements are documented as optional steps.
5. **Agent order:** Codex first, then Copilot. Cursor and Gemini follow later.
6. **Models:** Bedrock and Vertex require an explicit model. Direct API backends use the vendor default, with the pin documented in the workflow.
7. **Small root.** Only what tools require is visible at the repo root. `CLAUDE.md` lives in `.claude/`, `SECURITY.md` in `.github/`, the review checklist and the experiment and research logs in `docs/`, and `references.bib` in `literature/`. `CONTRIBUTING.md` stays at the root. The study profile keeps `LEARNING_PLAN.md` and `PROGRESS.md` at the root.
