# Architecture

```
setup.sh             the entry point users run (wizard by default)
bin/harness          CLI: argument parsing and commands
lib/
  ui.sh              p10k-style terminal UI (one question per screen, single keys)
  wizard.sh          the ten configuration questions
  detect.sh          stack, package-manager, and default-branch detection; per-stack commands
  modules.sh         module registry, profiles and tiers, derived template flags
  render.sh/.awk     template engine
  apply.sh           writing files into the target repo (create-only, append, --force)
  settings.sh        composing .claude/settings.json from module contributions
  custom.sh          project-specific TODO(team) stubs (--skills, --roles, --rules, --dirs)
modules/<name>/
  module.sh          MODULE_DESC + module_apply()
  ...                templates
modules/custom/      stub templates used by custom.sh (not a selectable module)
profiles/*.profile   TITLE, DESC, GUARD_LEVEL, STRICT_GUARD, and MINIMAL / RECOMMENDED / STRICT module lists
tests/run.sh         end-to-end test suite
```

## Design rule: one shot, no footprint

harness runs once per repository. Everything it writes is a plain file the team owns from then on, so nothing generated may depend on harness: no config or manifest, no managed blocks, no links or paths back to this repo, no `harness ...` commands in docs. `test_no_harness_footprint` enforces this. If a feature would need harness again later, it belongs in the generated files instead (a script, a Makefile target, a workflow), or it doesn't ship.

## A run, end to end

1. **Answers.** Defaults come from detection, then CLI flags (`--cmd KEY=CMD` overrides individual commands), then the wizard. Every answer is an `HV_*` environment variable, e.g. `HV_TEST_CMD`. Nothing is saved.
2. **Derived flags.** `derive_vars` computes booleans for templates: `MOD_<MODULE>`, `STACK_<STACK>`, `PM_<MANAGER>`, `GUARD_STRICT`, `MULTI_AGENT`, `HAS_COMMANDS`, `USE_MAKE` (devtools on and the Makefile is ours to write), `SCAFFOLD_PYTHON` (devtools, Python/uv, no `pyproject.toml` yet), plus `PY_PACKAGE`, `CODEQL_LANGUAGE`, `DEPENDABOT_ECOSYSTEM`, and others.
3. **Modules.** Each selected module's `module_apply` runs in canonical order. It calls `emit MODE SRC DEST` for files and `settings_allow|ask|deny|env|hook` for settings.
4. **Stubs.** `custom_apply` emits the project-specific TODO(team) stubs.
5. **Settings.** Once all modules have contributed, `settings.json` is rendered and emitted like any other file.

## Write modes (`emit MODE ...`)

| Mode | File missing | File exists | With `--force` |
|---|---|---|---|
| `file` | created | skipped | overwritten (or reported unchanged) |
| `exec` | as `file`, plus `chmod +x` | | |
| `append` | created | template lines it lacks are appended (comments and blanks ignored); idempotent | same |

`seed` is an alias of `file`. Nothing is ever deleted.

## Template language

```
{{NAME}}                         value of HV_NAME (unknown names are left as-is,
                                 so GitHub's ${{ ... }} passes through)
{{#if NAME}} / {{#unless NAME}}  on their own line, closed by {{/if}}; nestable
a{{#if NAME}}b{{/if}}c           inline form on one line, not nestable
{{> file.md}}                    on its own line: include $MODULE_DIR/file.md
                                 (partials may include partials, up to 5 deep)
```

A value is falsy when it is empty, `0`, `false`, `no`, or `off`.

## Adding a profile

1. Create `profiles/<name>.profile` with `TITLE`, `DESC`, `GUARD_LEVEL`, `STRICT_GUARD`, `MINIMAL`, `RECOMMENDED`, and `STRICT`.
2. Add `<name>` to `ALL_PROFILES` in `lib/modules.sh`. Templates get `PROFILE_<NAME>`; also decide whether it counts as `PROFILE_ENGINEERING` (PR-centric agreement) or `PROFILE_SOLO` (no PR flow).
3. Usually add a same-named module (`modules/<name>/`) for its skills and seed files, plus `modules/core/agreements/<name>.md`, which is included in `CLAUDE.md` when the module is on.
4. Extend `test_every_profile_and_tier` and `test_profile_specifics` in `tests/run.sh`.

## Writing a module

```sh
mkdir -p modules/mymod
cat > modules/mymod/module.sh <<'EOF'
# shellcheck shell=bash
MODULE_DESC="One line shown in the wizard and in 'harness list'"

module_apply() {
  emit file my-workflow.yml .github/workflows/my-workflow.yml
  emit exec hooks/my-hook.sh .claude/hooks/my-hook.sh
  settings_hook PreToolUse Bash my-hook.sh 10
  settings_allow 'Bash(make build:*)'
}
EOF
```

Then add the module name to `ALL_MODULES` in `lib/modules.sh` (that list sets the order) and, if appropriate, to the tiers in `profiles/*.profile`. Hooks should source `lib.sh` (`. "$(dirname "$0")/lib.sh"`) to get `hook_field`, `hook_block`, and `hook_log`. Add a test to `tests/run.sh`; the `test_every_stack` test already fails on any unrendered `{{PLACEHOLDER}}`.

## Compatibility rules

- bash 3.2: no associative arrays, `mapfile`, `${var,,}`, or `declare -n`. CI runs the suite on macOS with `/bin/bash` and BSD awk.
- POSIX awk only (no gawk extensions). Avoid awk reserved words as variable names (`close`, `index`, ...).
- Generated hooks must work without `jq`. `lib.sh` falls back to python3, then to sed.
