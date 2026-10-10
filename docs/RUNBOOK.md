# Runbook: setting up a development harness for your project

This is a teaching document. It assumes you can use git and a terminal, and that you have tried a coding agent such as Claude Code at least once. It assumes nothing about "harness engineering". Read Part 1 once for the ideas, then follow Part 2 step by step with your own repository open.

- Part 1: the ideas (10 minutes of reading)
- Part 2: the runbook (about an hour, most of it spent writing your project's context)
- Part 3: living with the harness (what to do in week 2 and beyond)
- Part 4: troubleshooting and glossary

---

## Part 1: The ideas

### 1.1 What a harness is

A coding agent is a language model in a loop: it reads files, runs commands, edits code, and decides what to do next. The model supplies the intelligence. Everything around the model is the **harness**: what it is told about your project, which commands it may run, what stops it from doing damage, how its work gets checked, and how you find out what it did.

A useful comparison is a new engineer joining your team. A capable hire still needs:

| A new engineer needs | The harness equivalent | Where it lives |
|---|---|---|
| An onboarding doc | Project context | `AGENTS.md` |
| Team conventions for specific areas | Path-scoped rules | each agent's rules folder, e.g. `.claude/rules/` |
| Runbooks for recurring procedures | Skills | `.agents/skills/` |
| Colleagues with specialities | Subagents (roles) | each agent's folder, e.g. `.claude/agents/` |
| Access rights | Permissions | each agent's settings, e.g. `.claude/settings.json` |
| Safety interlocks on dangerous machinery | Hooks | `.agents/hooks/` |
| Code review and CI | The PR gate | `.github/workflows/` |
| A manager who can see what happened | Audit log, scorecards, weekly digest | `.agents/logs/`, PR comments, issues |

Without a harness, each person on the team prompts the agent differently, the agent rediscovers the project every session, and nothing prevents a confident mistake from reaching `main`. With one, the agent starts every session knowing the project, the dangerous actions are physically blocked, and every change passes the same checks.

### 1.2 Guidance versus enforcement

This is the single most important idea in the whole document.

- **Guidance** is text the model reads: `AGENTS.md`, rules, skills. The model usually follows it. "Usually" means it can be forgotten in a long session, misread, or outweighed by something else in the conversation.
- **Enforcement** is code that runs outside the model: permissions, hooks, and CI checks. It behaves the same way every time, whatever the model thinks.

The practical rule: **if something must always hold, enforce it; if it is a preference or a piece of knowledge, write it as guidance.**

| Requirement | Right mechanism | Why |
|---|---|---|
| "Never force-push" | Hook | A single violation is costly, so it needs a mechanical block |
| "Never read `.env`" | Permission deny rule | Same reason |
| "Tests must pass before you finish" | Stop hook | The agent cannot declare victory on a red build |
| "We prefer small functions" | `AGENTS.md` or a rule | A judgement call, fine as guidance |
| "How to run a benchmark" | Skill | A procedure, loaded only when needed |

People new to this tend to put everything in `AGENTS.md` in capital letters. That produces a long file the model skims and a false sense of safety. Keep `AGENTS.md` short and move the hard rules into hooks and CI.

### 1.3 The layers, one at a time

**Context: `AGENTS.md`.** Loaded at the start of every session. It should hold the facts the agent needs every single time: what the project is, the domain vocabulary, the main components, the commands to run, the invariants, and the known traps. Every line costs attention in every session, so it stays short.

`AGENTS.md` is a convention most coding agents read (Codex CLI, Cursor, GitHub Copilot, and others), so it is the single source of truth here. Claude Code reads `CLAUDE.md`, which in this harness is a short file at `.claude/CLAUDE.md` that imports `AGENTS.md`. Write guidance once, in `AGENTS.md`.

**Path-scoped rules** (for Claude Code: `.claude/rules/*.md`). A rule file starts with a `paths:` line listing file patterns. It is loaded only when the agent touches a matching file. A rule about writing tests loads when the agent edits a test and stays out of the way otherwise. This keeps the always-loaded context small.

```markdown
---
paths: ["src/solver/**"]
---
# Solver code
- Every constraint has a name that appears in the model documentation.
- ...
```

**Skills: `.agents/skills/<name>/SKILL.md`.** A skill is a written procedure: numbered steps, how to verify the result, what to report. The agent sees only each skill's one-line description until the skill is needed, then loads the whole thing. You can also invoke one yourself with `/<name>`. Use skills for anything you would otherwise explain repeatedly: "how we run an experiment", "how we take a PR to green". This harness ships `review` (run the independent reviewer) and `handoff` (write a summary so a fresh session can continue the work). Skills live in `.agents/skills/`, a folder most agents read; Claude Code reaches it through the `.claude/skills` link.

**Subagents (roles)** (for Claude Code: `.claude/agents/<name>.md`). A subagent is a separate agent with its own fresh context and its own restricted tool list. The main agent hands it a task and receives a summary back. Two reasons to use one:
- *Independence.* The context that wrote a change is the worst one to review it, because it already believes its own reasoning. A `reviewer` subagent sees only the diff.
- *Focus.* Exploration produces a lot of output. A subagent absorbs that noise and returns the conclusion.

**Permissions** (for Claude Code: `.claude/settings.json`). Three lists. `allow` holds commands the agent may run without asking (your lint and test commands). `deny` holds things it may never do (reading secret files). `ask` holds things that need a human click each time. Good permissions make the agent faster, because it stops asking about safe commands, and safer, because the dangerous ones are closed off.

**Hooks: `.agents/hooks/*.sh`.** Small scripts that the agent runs at fixed moments. Each receives a JSON description of what is about to happen and can block it. The scripts are shared; each agent's settings file says when to call them (for Claude Code, the `hooks` section of `.claude/settings.json`).

| Moment | Hook in this harness | What it does |
|---|---|---|
| Session starts | `session-start.sh` | Installs dependencies so tests can run |
| Before a shell command | `guard-bash.sh` | Blocks destructive commands |
| Before a file edit | `guard-paths.sh` | Blocks edits to secrets and protected paths |
| After a file edit | `format-on-edit.sh` | Formats the file the agent just changed |
| After any tool call | `audit-log.sh` | Appends one line to the audit log |
| Agent tries to finish | `stop-checks.sh` | Runs lint and typecheck; a failure sends the agent back to fix it |

When a hook blocks something, the agent is told why and what to do instead. A block is the system working as designed.

**The PR gate: `.github/workflows/pr-gate.yml`.** Local hooks protect one developer's machine. The gate protects the shared branch. Every pull request gets a single required check made of:
- *Diff guard:* inspects every PR the same way, whoever or whatever wrote it, and flags risky patterns such as deleted tests, removed assertions, edits to CI files, very large diffs, and new dependencies.
- *AI review* (strict tier): a fresh model instance reviews the diff against criteria your team owns in `scripts/ci/review/criteria.md`.
- *Scorecard:* a comment on the PR listing every signal and a score, so a human reviewer sees the picture at a glance.

**Monitoring.** Three views, from closest to furthest:
- *Audit log:* `.agents/logs/events.jsonl` on each developer's machine records tool calls and blocks. `.agents/scripts/agent-report.sh --days 7` summarises it.
- *Scorecards:* one per PR.
- *Weekly digest:* a GitHub issue with PR volume, merge and revert rates, gate scores, and which review findings people dismissed. Dismissals tell you which review criteria need sharpening.

### 1.4 What powerharnessing11k does, and where it stops

Building all of the above by hand takes days. powerharnessing11k is a wizard that writes it into your repository in about a minute, tailored to your answers.

It then **leaves**. It runs once per repository. It writes ordinary files, keeps no config or state, and nothing it writes refers back to it. From that point your team owns the harness and changes it like any other code. Nobody else on the team installs anything.

It also does not guess your domain. It cannot know your solver, your data sources, or your review checklist. For those it creates blank files in the right places, each marked `TODO(team)` with instructions on what to write. Filling those in is the real work of setting up a harness, and Part 2 walks you through it.

---

## Part 2: The runbook

### Step 0: Prerequisites

- git, and bash 3.2 or newer (stock macOS is fine)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed, to use the result
- For the Python path: [uv](https://docs.astral.sh/uv/)
- A GitHub repository (it may be empty), with admin rights for the final settings step

### Step 1: Decide a few things before you run anything

The wizard is quick. The decisions behind the answers deserve a few minutes of thought.

| Decision | How to think about it |
|---|---|
| **Profile** | What is the repo for? `software` for apps, services, and libraries. `ml` when notebooks, datasets, and experiments are central. `agentic` when the product itself is an LLM app. `study` and `research` for solo learning and research work. A numerical or optimisation codebase is `software` plus data versioning. |
| **Tier** | Start with `recommended`. `strict` adds AI review on every PR (needs an API key and has a running cost) and tighter guardrails. Move to strict once the team is comfortable. |
| **Data and models** | Does the project depend on data or model files that should not be in git yet must be reproducible? If yes, turn on artifact versioning. |
| **Your domain** | List two or three procedures you expect to explain repeatedly (skills), any specialist reviewer you want (role), and the areas of code with their own conventions (rules). Names only. You fill them in later. |
| **Who approves** | Which GitHub users or teams must review changes? They go in CODEOWNERS. |

### Step 2: Get the tool

Clone it once, anywhere. Nothing is installed and nothing goes on your `PATH`.

```sh
git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
```

### Step 3: Run the wizard in your project

```sh
cd ~/work/my-project        # an empty folder is fine; it offers to run git init
~/powerharnessing11k/setup.sh
```

Ten screens, one key each. `r` restarts, `q` quits without writing anything.

| # | Screen | Tip |
|:-:|---|---|
| 1 | What is this repository for? | Your profile from Step 1 |
| 2 | Language or toolchain | Detected from existing files; pick one in an empty folder |
| 3 | Commands | Check these carefully. Hooks, CI, and the agent's instructions all use them. Choose "Edit them" if any are wrong |
| 4 | Which coding agents | A checklist. Tick every agent your team uses (Claude Code, Codex CLI, GitHub Copilot); number keys toggle, Enter continues |
| 5 | How much harness | `Recommended` to start |
| 6 | Version data or model files? | Your decision from Step 1 |
| 7 | Project-specific stubs | Type the names from Step 1 |
| 8 | Who must review changes | CODEOWNERS entries, for example `@acme/platform` |
| 9 | Telemetry | "No" unless you already run an OpenTelemetry collector. Asked only when Claude Code is selected |
| 10 | Ready to apply | Read the summary, including what each agent does and does not get, then `y` |

If you pick GitHub Copilot: the CLI uses the hooks once you trust the folder, and the cloud agent reads the hooks, agents, and instructions from the default branch, so they apply after your bootstrap PR is merged.

If you pick Codex CLI: after the bootstrap, open the repo with `codex`, trust the project, and run `/hooks` to approve the hooks. Codex ignores a project's hooks until you do, and asks again whenever one changes.

To try it on a repository without committing anything, add `--local-only` (or press `l` on the last screen): the files are written as usual and listed in `.git/info/exclude`, so git ignores them on your machine only. Skip Steps 8 and 9 in that case.

To preview first, add `--dry-run`. To skip the questions entirely, pass flags:

```sh
~/powerharnessing11k/setup.sh --yes --stack python --artifacts \
  --skills formulate,run-solver --roles model-checker \
  --rules "solver=src/*/solver/**" --dirs infra
```

The wizard only creates files that do not exist yet. Existing files are left alone.

### Step 4: Read what was written

Spend five minutes here before changing anything. Open these in order:

1. `AGENTS.md` - what the agent reads first. Note the empty **Project context** section.
2. `.claude/CLAUDE.md` - one import line. Then `.claude/settings.json` - the `allow` and `deny` lists, and which hook runs at which moment.
3. `.agents/hooks/guard-bash.sh` - plain bash. Read the list of blocked patterns so you know what your agent cannot do.
4. `Makefile` - the commands everyone shares. Run `make help`.
5. `.github/workflows/ci.yml` and `pr-gate.yml` - what happens to every PR.
6. `docs/agents/HANDBOOK.md` - the team policy in plain language.
7. `docs/TESTING.md` - the test tiers and rules.

### Step 5: Prove the guardrails work

Do not take enforcement on trust. Feed the guard hook a dangerous command by hand:

```sh
echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin feature"}}' \
  | .agents/hooks/guard-bash.sh claude; echo "exit code: $?"
```

Expected:

```
Blocked by guardrail: force-push rewrites shared history
If this is genuinely required, stop and ask a human to do it.
exit code: 2
```

The last word on the command line names the agent calling the hook. Exit code 2 is the signal that tells Claude Code to stop the action. A harmless command such as `git status` in the same test exits 0.

Then check the project itself is healthy:

```sh
make setup     # install dependencies and dev tools
make check     # lint + typecheck + fast tests: the bar every PR must clear
```

On a fresh Python scaffold both pass immediately.

### Step 6: Write your project's context (the important step)

The wizard listed every file containing `TODO(team)`. Find them again any time with:

```sh
grep -rl 'TODO(team)' .
```

Work through them in this order.

**6a. `AGENTS.md`, the Project context section.** Six short entries. Aim for a page in total.

| Entry | Write | Avoid |
|---|---|---|
| What this is | The problem, who it is for, what "done" looks like | Marketing language |
| Domain terms | Words with a precise meaning here | Definitions anyone could look up |
| Key libraries and tools | The ones that shape the code, with version constraints | A full dependency list |
| Architecture | Main components, how data flows, where to start reading | A file-by-file tour |
| Constraints and invariants | What must always hold: correctness rules, performance budgets | Style preferences |
| Gotchas | Surprises that have cost someone time | Anything already enforced by a hook |

A test for each line: would a capable engineer who is new to this repo make a mistake without it? If the answer is no, cut it.

**6b. Skill stubs, `.agents/skills/<name>/SKILL.md`.** Two parts matter most.
- The `description` line. The agent decides whether to load a skill from this line alone, so name the situations that should trigger it. "Use when adding or changing a constraint in the optimisation model" works. "Solver helper" does not.
- The body: when to use it and when not to, the inputs to gather, numbered steps with a checkable outcome each, how to verify the result, and what to report back.

**6c. Rule stubs, `.claude/rules/<name>.md`.** Check the `paths:` pattern matches the files you mean. Then write short, specific bullets that apply only to those files. A good rule states the convention and the reason.

**6d. Role stubs, `.claude/agents/<name>.md`.** Write what this specialist checks, what it should ignore, and the exact shape of its report. Leave the tool list read-only unless the role truly needs to change files. A reviewer that can edit is no longer independent.

**6e. The remaining TODOs.** `docs/TESTING.md` (your domain's invariants, reference cases with known answers, runtime budgets), `data/README.md` and `models/README.md` (where the files come from), and the description in `pyproject.toml`.

### Step 7: Record your data and models (if you enabled artifacts)

The files in `data/` and `models/` stay out of git. Their hashes go in `artifacts.lock`, which is committed, so every commit names the exact inputs it was built and tested with.

```sh
cp ~/downloads/instances.parquet data/raw/
scripts/artifacts.sh snapshot -m "initial benchmark instances"
scripts/artifacts.sh verify      # exit 1 if any recorded file is missing or changed
git add artifacts.lock
```

Teammates obtain the same files however your team shares them today (a shared drive, a download script), then run `scripts/artifacts.sh verify` to confirm they hold identical copies. `docs/ARTIFACTS.md` explains the later move to cloud storage.

### Step 8: Commit and open the bootstrap PR

```sh
git checkout -b chore/bootstrap-harness
git add -A
git commit -m "chore: bootstrap agent harness"
git push -u origin chore/bootstrap-harness
```

Open a pull request and have a teammate review it. This PR is the moment the team agrees on its rules, so treat the review as a discussion of those rules.

### Step 9: Configure GitHub (once, by a repo admin)

| Setting | Where | Value |
|---|---|---|
| Branch protection on `main` | Settings - Branches | Require a pull request, at least one approval, and passing status checks |
| Required checks | Same screen | `CI` and `PR gate / gate` |
| Code owner review | Same screen | Enable "Require review from Code Owners" |
| API key (strict tier only) | Settings - Secrets and variables - Actions | `ANTHROPIC_API_KEY` |

Without branch protection the gate only advises. With it, nothing reaches `main` unchecked.

### Step 10: Run your first agent task

Pick something small and well specified. Open an issue with the **Agent task** template: a goal, testable acceptance criteria, pointers to relevant files, and what is out of scope.

Then, in the repo:

```sh
claude
```

and give it the task. Watch what the harness does:

1. The agent starts already knowing your project, because it read `AGENTS.md`.
2. It runs `make test` without asking, because that command is on the allow list.
3. When it edits a test file, the testing rule loads.
4. Its edits are formatted automatically.
5. If it tries to finish with lint failing, the stop hook sends it back.
6. Run the `review` skill (`/review` in Claude Code) before opening the PR. The reviewer subagent reads the diff with fresh eyes.
7. On the PR, the gate runs the same checks it runs on every PR and posts a scorecard. Nothing asks how the change was written.
8. A human approves and merges. A human owns every merge.

Afterwards, look at what happened:

```sh
.agents/scripts/agent-report.sh --days 1
```

---

## Part 3: Living with the harness

The harness is yours now. powerharnessing11k is not involved again. These are the habits that keep it useful.

### 3.1 The core loop: fix the harness, then the PR

When an agent makes a mistake, ask which layer should have prevented it, and fix that layer in the same PR or the next one.

| What you observed | Fix |
|---|---|
| The agent lacked a fact about the project | Add one line to `AGENTS.md` |
| It broke a convention in one area of the code | Add or extend a rule in `.claude/rules/` |
| You explained the same procedure a second time | Write a skill |
| It did something that must never happen | Add a hook pattern or a deny rule |
| A bad change passed review | Sharpen `scripts/ci/review/criteria.md` or add a CI check |
| It keeps asking permission for a safe command | Add the command to `allow` in `.claude/settings.json` |
| A guardrail blocks legitimate work | Narrow the pattern in the hook, through a PR |

A harness that never changes is being ignored. Expect a few small edits a week at first.

### 3.2 Changing a guardrail

Guardrails are code in your repo, so the process is a normal PR:

1. Edit the hook in `.agents/hooks/` or the lists in your agent's settings (`.claude/settings.json`).
2. Test it by hand with the command from Step 5.
3. Open a PR and get it reviewed. At the strict guard level these files are human-only, so an agent cannot loosen its own rules.

Never work around a guardrail locally. If the rule is wrong, change the rule for everyone.

### 3.3 Adding a skill, a rule, or a role later

Create the file by hand in the matching folder, copying the frontmatter from an existing one:

- Skill: `.agents/skills/<name>/SKILL.md` with `name` and `description`
- Rule (Claude Code): `.claude/rules/<name>.md` with `paths`
- Role (Claude Code): `.claude/agents/<name>.md` with `name`, `description`, and `tools`

### 3.4 Reading the signals

- **Each PR:** read the scorecard before the diff. It tells you where to look.
- **Weekly:** read the digest issue. Rising reverts point to weak tasks or weak context. Review findings that people keep dismissing point to criteria that need editing or switching off.
- **Monthly:** reread `AGENTS.md` as a team and delete what is stale. Shorter is better.

### 3.5 When the gate blocks a PR

Read the scorecard. Fix what it names and push again. If a finding is wrong and the change is safe, a maintainer other than the author adds the `gate-override` label. The override is recorded and shows up in the digest, which keeps overrides honest.

### 3.6 Tests in tiers

`make test` runs the fast tier on every change. `make test-all` runs everything, including slow, regression, and benchmark tests, and runs nightly in CI. Mark slow tests so the fast tier stays fast:

```python
@pytest.mark.slow
def test_full_instance_solves_to_optimality(): ...
```

Golden results are reviewed when they change. Regenerating them to make a failure disappear is the testing equivalent of deleting the test.

### 3.7 Long sessions and handoffs

Agent context fills up. When a session has been running for a long time, run the `handoff` skill. It writes a summary of the goal, the decisions made, the files changed, and the next steps. Start a fresh session from that file. A fresh session with a good summary is more reliable than a long one with stale details.

---

## Part 4: Troubleshooting and glossary

### Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| "Blocked by guardrail: ..." | A hook stopped a risky action | Read the reason. Usually there is a safer route. If the rule is wrong, see 3.2 |
| A harmless command is blocked because its text contains a dangerous one | The guard matches command text, including quoted strings | Rephrase the command or put the text in a file. Narrow the hook pattern if it recurs |
| The agent cannot finish; lint or typecheck keeps failing | The stop hook is doing its job | Let the agent fix it, or run `make lint` yourself to see the error |
| The agent keeps asking permission for the same command | The command is missing from the allow list | Add it to `permissions.allow` in `.claude/settings.json` |
| Hooks do not run at all | Files lost their executable bit, or settings were not loaded | `chmod +x .agents/hooks/*.sh`, then restart your agent |
| Hooks do not run in Copilot | The folder is not trusted (CLI), or the files are not on the default branch yet (cloud agent) | Trust the folder; merge the bootstrap PR |
| Hooks do not run in Codex CLI | The project is not trusted, or the hooks were not approved (or changed since) | Trust the project when Codex asks, then run `/hooks` and approve them |
| Claude Code finds no skills on Windows | `.claude/skills` is a symbolic link, and git checked it out as a text file | Enable Developer Mode, run `git config --global core.symlinks true`, and clone again |
| A rule never seems to apply | Its `paths:` pattern does not match the files | Compare the pattern with real paths in the repo |
| A skill is never used | Its `description` does not say when to use it | Rewrite the description around trigger situations |
| CI fails at "Typecheck" in an existing Python repo | A typecheck command is configured without matching tool config | Configure the tool in `pyproject.toml`, or clear the command in the Makefile and CI |
| PR gate stays pending | The AI review has not finished, or the API key is missing | Check the workflow run, and the `ANTHROPIC_API_KEY` secret on strict tier |
| `scripts/artifacts.sh verify` fails | A data or model file differs from the recorded one | Run `scripts/artifacts.sh status` to see which. Restore the file, or snapshot deliberately and say why in the PR |
| Re-running `setup.sh` changed nothing | Expected. It only creates missing files | Edit the files directly. They are yours |

### Glossary

| Term | Meaning |
|---|---|
| **Agent** | A language model running in a loop with tools: it reads, runs commands, edits, and decides the next step |
| **Harness** | Everything around the model: context, permissions, hooks, checks, and monitoring |
| **Context** | What the model can see in a session. It is finite, so what goes in matters |
| **`AGENTS.md`** | The project file every agent loads at the start of a session; `.claude/CLAUDE.md` imports it |
| **Rule** | Guidance loaded only for matching file paths |
| **Skill** | A written procedure loaded on demand, invoked automatically or with `/<name>` |
| **Subagent / role** | A separate agent with fresh context and limited tools, used for independent or noisy work |
| **Permission** | An allow, ask, or deny entry for a tool or command |
| **Hook** | A script Claude Code runs at a fixed moment, able to block the action |
| **Guard level** | How strict the hooks are: relaxed, standard, or strict |
| **PR gate** | The single required CI check combining diff guard, AI review, and the scorecard |
| **Scorecard** | The PR comment that lists every gate signal and a score |
| **Digest** | The weekly issue summarising agent activity and review quality |
| **Artifact lock** | `artifacts.lock`: the committed list of hashes that pins data and model files |
| **Fast tier / full tier** | Tests run on every change versus the complete suite run nightly |
| **Handoff** | A written summary that lets a fresh session continue earlier work |

### Where to go next

- `README.md` - every option and what each profile includes
- `docs/ARCHITECTURE.md` - how powerharnessing11k itself is built, for adding a module or profile
- `docs/CCAR-ALIGNMENT.md` - the published practices behind these choices
- `docs/agents/HANDBOOK.md` in your bootstrapped repo - your team's policy, ready to edit
