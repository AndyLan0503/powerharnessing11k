## Project

- Purpose: {{PROFILE_TITLE}}
- Stack: {{STACK}} (`{{PKG_MANAGER}}`)
{{#if PROFILE_SOLO}}
- Default branch: `{{DEFAULT_BRANCH}}`. This is a personal repo: committing straight to it is fine. Commit small and often, with messages that say what changed.
{{/if}}
{{#unless PROFILE_SOLO}}
- Default branch: `{{DEFAULT_BRANCH}}`. Never commit to it directly: branch, then open a PR.
{{/if}}
{{#if HAS_COMMANDS}}

## Commands

{{#if USE_MAKE}}
The `Makefile` is the single entry point for humans, agents, and CI (`make help` lists everything):

- `make setup`: install dependencies and dev tools
- `make check`: lint, typecheck, and the fast test tier. Run it before saying a task is done.
- `make test-all`: the full test tier, including slow, regression, and benchmark tests
- `make fmt`: reformat the code base
{{#if MOD_ARTIFACTS}}
- `make artifacts-verify`: confirm local data and models match `artifacts.lock`
{{/if}}
{{#if MOD_DEVTOOLS}}
- Test tiers and rules: `docs/TESTING.md`
{{/if}}

Underlying commands:
{{/if}}
{{#if INSTALL_CMD}}
- Install: `{{INSTALL_CMD}}`
{{/if}}
{{#if LINT_CMD}}
- Lint: `{{LINT_CMD}}`
{{/if}}
{{#if TYPECHECK_CMD}}
- Typecheck: `{{TYPECHECK_CMD}}`
{{/if}}
{{#if TEST_CMD}}
- Test: `{{TEST_CMD}}`
{{/if}}
{{#if FULL_TEST_CMD}}
- Full test tier: `{{FULL_TEST_CMD}}`
{{/if}}
{{#if EVAL_CMD}}
- Evals: `{{EVAL_CMD}}`
{{/if}}
{{/if}}
{{#unless HAS_COMMANDS}}
{{#if PROFILE_ENGINEERING}}

## Commands

- TODO(team): no commands configured yet. List the install, lint, typecheck, and test commands here.
{{/if}}
{{/if}}
{{#if PROFILE_ENGINEERING}}

Run lint and tests before you say a task is done, and report the result honestly.

## Working agreement for agents

1. **Start from intent.** Work from an issue or a clear task statement. Restate the acceptance criteria before writing code; if they are missing, ask.
2. **Stay in scope.** Keep each change small and focused on the task. Propose unrelated refactors instead of doing them.
3. **Tests are the contract.** Add or update tests with every behavior change. Never delete, skip, or weaken a test to get CI green.
4. **Never bypass guardrails.** No `--no-verify`, no force-push, no disabling hooks or CI checks. If a guardrail hook blocks you, stop and explain what you needed.
5. **Secrets stay secret.** Never read `.env*` files or print credentials. Use `.env.example` for the shape of configuration.
6. **Commit hygiene.** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
7. **Dependencies are decisions.** Don't add one without stating why in the PR description.
8. **A human owns every merge.** Agents open PRs; humans approve them.
{{/if}}
{{#if HOW_WE_WORK}}

{{> how-we-work.md}}
{{/if}}
{{#if MOD_ML}}

{{> ../ml/rules/profile.md}}
{{/if}}
{{#if MOD_AGENTIC}}

{{> ../agentic/rules/profile.md}}
{{/if}}
{{#if MOD_STUDY}}

{{> ../study/rules/profile.md}}
{{/if}}
{{#if MOD_RESEARCH}}

{{> ../research/rules/profile.md}}
{{/if}}

## Guardrails (level: {{GUARD_LEVEL}})

{{#if GUARD_RELAXED}}
Hooks block only catastrophic actions: recursive deletes of `/` or `~`{{#unless PROFILE_SOLO}}, pushing straight to `{{DEFAULT_BRANCH}}`{{/if}}, and edits to secret files.
{{/if}}
{{#if GUARD_STANDARD}}
Hooks in `.agents/hooks/` block destructive commands (force-push, `--no-verify`, `rm -rf` of root/home, piping downloads into a shell{{#unless PROFILE_SOLO}}, pushing straight to `{{DEFAULT_BRANCH}}`{{/if}}) and edits to secret files.
{{/if}}
{{#if GUARD_STRICT}}
Strict mode. In addition to the standard rules, these paths are human-only: `.github/workflows/`, `scripts/ci/`, `CODEOWNERS`, `.agents/hooks/`{{PROTECTED_TEXT}}. `git reset --hard` and any force-push are blocked, and lint/typecheck must pass before you finish.
{{/if}}
{{#if PROTECT_RAW_DATA}}
`data/raw/` is read-only for agents: raw data is immutable. Write derived data to `data/processed/` (or `data/interim/`) with the script that produced it.
{{/if}}
{{#if MOD_STUDY}}
`exercises/` is the learner's own work: agents may read it and comment, but never edit it.
{{/if}}
{{#if MOD_AUDIT}}
Blocked actions are logged to `.agents/logs/events.jsonl` (git-ignored).
{{/if}}

## Where things live

- `AGENTS.md` (this file): the source of truth for project context and rules, for every coding agent.
- `.agents/skills/`: procedures any agent can follow on demand. `.agents/hooks/`: the guard scripts every agent's hooks call.
{{AGENT_LAYOUT}}
- All of it is ordinary code: change it through a PR like anything else.
{{#if MOD_AUDIT}}
- `.agents/scripts/agent-report.sh`: summary of local agent activity and blocked actions.
{{/if}}
{{#if MOD_COLLAB}}
- `CONTRIBUTING.md` and `docs/agents/HANDBOOK.md`: how humans and agents collaborate here.
{{/if}}
{{#if MOD_REVIEW}}
- `REVIEW.md`: the review checklist used by humans and the AI review in the PR gate.
{{/if}}
{{#if MOD_SKILLS}}
- Skills `steward` and `task-intake`: driving PRs to green, starting work well.
{{/if}}
{{#if MOD_ML}}
- `EXPERIMENTS.md`: experiment log. `docs/DATA.md`: dataset cards. Skills: `experiment`, `data-audit`.
{{/if}}
{{#if MOD_AGENTIC}}
- `prompts/`: versioned prompts. `evals/`: eval cases and how to run them. Skills: `prompt-change`, `agent-tool`.
{{/if}}
{{#if MOD_STUDY}}
- `LEARNING_PLAN.md`, `PROGRESS.md`, `notes/`, `exercises/`. Skills: `tutor`, `quiz`, `study-plan`.
{{/if}}
{{#if MOD_RESEARCH}}
- `RESEARCH_LOG.md` (lab notebook), `literature/`, `references.bib`. Skills: `lit-review`, `lab-notebook`, `claim-check`.
{{/if}}
