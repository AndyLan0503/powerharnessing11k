# shellcheck shell=bash
# Provider-neutral settings. Modules state what they need in plain terms (a
# command that may run unprompted, a file that must not be read, a hook at a
# lifecycle moment); each agent adapter (agents/<name>/adapter.sh) turns the
# collected entries into that agent's own configuration files.
#
# Hook events (see docs/design/providers.md for the per-agent mapping):
#   session-start  a session begins
#   pre-shell      before a shell command runs (can block)
#   pre-edit       before a file is created or edited (can block)
#   post-edit      after a file was created or edited
#   post-tool      after any tool call
#   stop           the agent is about to finish its turn (can send it back)
SETTINGS_EVENTS="session-start pre-shell pre-edit post-edit post-tool stop"

settings_reset() {
  local f
  for f in allow_cmd ask_cmd deny_cmd deny_read allow_tool hooks agent; do : >"$HARNESS_TMP/settings.$f"; done
}

# Commands are written as a prefix, e.g. 'git status' or 'make test'.
settings_allow_cmd() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.allow_cmd"; }
settings_ask_cmd() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.ask_cmd"; }
settings_deny_cmd() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.deny_cmd"; }
# Paths or globs relative to the repo root, e.g. '.env' or '**/*.pem'.
settings_deny_read() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.deny_read"; }
# A built-in capability by neutral name. Known: websearch.
settings_allow_tool() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.allow_tool"; }

# settings_hook EVENT SCRIPT [TIMEOUT_SECONDS]
# SCRIPT is a file name under .agents/hooks/ in the target repo.
settings_hook() {
  list_has "$SETTINGS_EVENTS" "$1" || harness_die "module ${MODULE_NAME:-?}: unknown hook event '$1'"
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-30}" >>"$HARNESS_TMP/settings.hooks"
}

# settings_agent AGENT KIND KEY VALUE: a setting only one agent understands.
# KIND is "string" (a top-level setting) or "env" (an environment variable).
# Ignored when that agent is not selected.
settings_agent() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >>"$HARNESS_TMP/settings.agent"; }

# Unique lines of a settings list, in first-seen order.
settings_list() { awk '!seen[$0]++' "$HARNESS_TMP/settings.$1"; }
