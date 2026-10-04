# Architecture

```
bin/harness          CLI entry point: argument parsing and commands
lib/
  ui.sh              p10k-style terminal UI (one question per screen, single keys)
  wizard.sh          the seven configuration questions
  detect.sh          stack, package-manager, and default-branch detection; per-stack commands
  modules.sh         module registry, presets, derived template flags
  render.sh/.awk     template engine
  apply.sh           writing files into the target repo (ownership modes)
  settings.sh        composing .claude/settings.json from module contributions
  state.sh           .harness/config (answers) and .harness/manifest (checksums)
modules/<name>/
  module.sh          MODULE_DESC + module_apply()
  ...                templates
presets/*.preset     GUARD_LEVEL + MODULES
tests/run.sh         end-to-end test suite
```

## A run, end to end

1. **Answers.** Defaults come from detection, then are overlaid with `.harness/config` if it exists, then with CLI flags, then with the wizard. Every answer is an `HV_*` environment variable, e.g. `HV_TEST_CMD`.
2. **Derived flags.** `derive_vars` computes booleans for templates: `MOD_<MODULE>`, `STACK_<STACK>`, `PM_<MANAGER>`, `GUARD_STRICT`, `MULTI_AGENT`, `HAS_COMMANDS`, plus `CODEQL_LANGUAGE`, `DEPENDABOT_ECOSYSTEM`, and others.
3. **Modules.** Each selected module's `module_apply` runs in canonical order. It calls `emit MODE SRC DEST` for files and `settings_allow|ask|deny|env|hook` for settings.
4. **Settings.** Once all modules have contributed, `settings.json` is rendered (with `.harness/permissions` merged in) and applied as a managed file.
5. **State.** `.harness/config` and `.harness/manifest` are written, and orphans are reported: files that were managed before but are no longer produced by the current config. They are never deleted automatically.

## Ownership modes (`emit MODE ...`)

| Mode | Created | Updated when | If the user edited it |
|---|---|---|---|
| `file` | yes | its sha256 still matches the manifest | kept; proposal written to `<file>.harness-new` |
| `exec` | as `file`, plus `chmod +x` | | |
| `block` | yes, full template | always, but only between the markers | text outside the markers is never touched |
| `seed` | yes | never | n/a |

A pre-existing file that harness never wrote is treated like an edited one: harness keeps it and writes a proposal. `--force` takes harness's version everywhere.

## Template language

```
{{NAME}}                         value of HV_NAME (unknown names are left as-is,
                                 so GitHub's ${{ ... }} passes through)
{{#if NAME}} / {{#unless NAME}}  on their own line, closed by {{/if}}; nestable
a{{#if NAME}}b{{/if}}c           inline form on one line, not nestable
{{> file.md}}                    on its own line: include $MODULE_DIR/file.md
```

A value is falsy when it is empty, `0`, `false`, `no`, or `off`.

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

Then add the module name to `ALL_MODULES` in `lib/modules.sh` (that list sets the order) and, if appropriate, to a preset. Hooks should source `lib.sh` (`. "$(dirname "$0")/lib.sh"`) to get `hook_field`, `hook_block`, and `hook_log`. Add a test to `tests/run.sh`; the `test_every_stack` test already fails on any unrendered `{{PLACEHOLDER}}`.

## Compatibility rules

- bash 3.2: no associative arrays, `mapfile`, `${var,,}`, or `declare -n`. CI runs the suite on macOS with `/bin/bash` and BSD awk.
- POSIX awk only (no gawk extensions). Avoid awk reserved words as variable names (`close`, `index`, ...).
- Generated hooks must work without `jq`. `lib.sh` falls back to python3, then to sed.
