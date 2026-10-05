# shellcheck shell=bash
# Coding-agent adapters. Modules emit provider-neutral content (rules, skills,
# roles); every selected agent's adapter places it where that agent reads it.
#
# An adapter is agents/<name>/adapter.sh and defines:
#   AGENT_TITLE                      name shown to the user
#   agent_<name>_begin               files the agent always needs
#   agent_<name>_skill NAME          a skill was written to .agents/skills/NAME
#   agent_<name>_rule NAME FILE      a rendered rule (frontmatter: paths)
#   agent_<name>_role NAME FILE      a rendered role (frontmatter: name, description, access)
#   agent_<name>_finish              settings, from lib/settings.sh's store
#
# Neutral formats:
#   rule   Markdown with frontmatter `paths: ["glob", ...]`. Rules always
#          have paths; guidance that applies everywhere belongs in AGENTS.md.
#   skill  The Agent Skills format: <name>/SKILL.md with name + description.
#          Written once to .agents/skills/, which most agents read directly.
#   role   Markdown with frontmatter name, description, and
#          `access: read | read-run | write` (read files; also run commands;
#          also edit files). Adapters translate access into tool limits.

ALL_AGENTS="claude"
SKILLS_DIR=.agents/skills
HOOKS_DIR=.agents/hooks

agent_title() { # name
  (
    AGENT_TITLE=$1
    # shellcheck disable=SC1090
    . "$HARNESS_ROOT/agents/$1/adapter.sh"
    printf '%s' "$AGENT_TITLE"
  )
}

# Template variables that describe the selected agents:
#   AGENT_LAYOUT       Markdown bullets: where each agent's own files are
#   AGENT_CODEOWNERS   CODEOWNERS lines for the paths each agent owns
#   PROTECTED_TEXT     ", `path`" for each file that holds guardrail settings
#   PROTECTED_CASE     " | path" for a shell case pattern
#   PROTECTED_REGEX    "|path$" for an extended regex
# Adapters declare AGENT_LAYOUT, AGENT_OWNED (space-separated paths), and
# AGENT_PROTECTED (space-separated files).
agents_export_vars() {
  local a p layout='' owners='' text='' pcase='' regex=''
  for a in $HV_AGENTS; do
    AGENT_LAYOUT='' AGENT_OWNED='' AGENT_PROTECTED=''
    # shellcheck disable=SC1090
    . "$HARNESS_ROOT/agents/$a/adapter.sh"
    layout="${layout:+$layout
}- $AGENT_LAYOUT"
    for p in $AGENT_OWNED; do
      owners="${owners:+$owners
}$(printf '%-23s %s' "/$p" "${HV_CODEOWNERS:-}")"
    done
    for p in $AGENT_PROTECTED; do
      text="$text, \`$p\`"
      pcase="$pcase | $p"
      regex="$regex|$(printf '%s' "$p" | sed 's/\./\\./g')\$"
    done
  done
  HV_AGENT_LAYOUT=$layout HV_AGENT_CODEOWNERS=$owners
  HV_PROTECTED_TEXT=$text HV_PROTECTED_CASE=$pcase HV_PROTECTED_REGEX=$regex
  export HV_AGENT_LAYOUT HV_AGENT_CODEOWNERS HV_PROTECTED_TEXT HV_PROTECTED_CASE HV_PROTECTED_REGEX
}

agents_validate() {
  local a
  [ -n "${HV_AGENTS:-}" ] || harness_die "select at least one coding agent (${ALL_AGENTS// /, })"
  for a in $HV_AGENTS; do
    list_has "$ALL_AGENTS" "$a" || harness_die "unknown coding agent: $a (${ALL_AGENTS// /, })"
  done
}

# Run FUNCTION-SUFFIX for every selected agent, with the adapter's directory
# as the template root.
_agents_each() { # suffix [args...]
  local suffix=$1 a saved_name=${MODULE_NAME:-} saved_dir=${MODULE_DIR:-}
  shift
  for a in $HV_AGENTS; do
    MODULE_NAME="agent:$a"
    MODULE_DIR=$HARNESS_ROOT/agents/$a
    export MODULE_DIR
    "agent_${a}_$suffix" "$@"
  done
  MODULE_NAME=$saved_name
  MODULE_DIR=$saved_dir
  export MODULE_DIR
}

agents_begin() { _agents_each begin; }

agents_finish() { _agents_each finish; }

_render_module_template() { # src -> sets RENDERED
  local src=$MODULE_DIR/$1
  [ -f "$src" ] || harness_die "module $MODULE_NAME: missing template $1"
  HARNESS_SEQ=$((${HARNESS_SEQ:-0} + 1))
  RENDERED=$HARNESS_TMP/render.$HARNESS_SEQ
  render_template "$src" "$RENDERED" || harness_die "module $MODULE_NAME: failed to render $1"
}

# emit_rule NAME SRC: a path-scoped rule.
emit_rule() {
  _render_module_template "$2"
  sed -n '2p' "$RENDERED" | grep -q '^paths: \[' ||
    harness_die "module $MODULE_NAME: rule $2 needs 'paths: [...]' on its second line"
  _agents_each rule "$1" "$RENDERED"
}

# emit_skill NAME SRC: one copy for every agent.
emit_skill() {
  emit file "$2" "$SKILLS_DIR/$1/SKILL.md"
  _agents_each skill "$1"
}

# emit_role NAME SRC: a subagent definition.
emit_role() {
  _render_module_template "$2"
  grep -Eq '^access: (read|read-run|write)$' "$RENDERED" ||
    harness_die "module $MODULE_NAME: role $2 needs 'access: read|read-run|write' in its frontmatter"
  _agents_each role "$1" "$RENDERED"
}

# emit_hook SRC: a hook script under .agents/hooks/, shared by all agents.
emit_hook() {
  emit exec "$1" "$HOOKS_DIR/$(basename "$1")"
}
