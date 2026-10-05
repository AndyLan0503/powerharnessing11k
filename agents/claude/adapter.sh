# shellcheck shell=bash
# Claude Code adapter.
#   instructions  CLAUDE.md, which imports AGENTS.md
#   rules         .claude/rules/<name>.md (the neutral format is Claude's own)
#   skills        .claude/skills -> ../.agents/skills (Claude reads only .claude/skills)
#   roles         .claude/agents/<name>.md, access translated to a tool list
#   settings      .claude/settings.json: permissions, hooks, env
AGENT_TITLE="Claude Code"
# shellcheck disable=SC2034 # read by lib/agents.sh
AGENT_LAYOUT='Claude Code: `CLAUDE.md` (imports this file), `.claude/settings.json` (permissions and hook wiring), `.claude/rules/` (path-scoped rules), `.claude/agents/` (subagents), `.claude/skills` (a link to `.agents/skills/`).'
# shellcheck disable=SC2034
AGENT_OWNED=".claude/ CLAUDE.md"
# shellcheck disable=SC2034
AGENT_PROTECTED=".claude/settings.json"

agent_claude_begin() {
  emit file CLAUDE.md.tmpl CLAUDE.md
  emit_symlink "../$SKILLS_DIR" .claude/skills
  emit append gitignore.tmpl .gitignore
}

# Claude Code reads skills only from .claude/skills. Normally that is one link
# to the shared folder. A repo that already has a real .claude/skills folder
# keeps it, and each shared skill is linked into it instead.
agent_claude_skill() { # name
  if [ -d "$TARGET/.claude/skills" ] && [ ! -L "$TARGET/.claude/skills" ]; then
    emit_symlink "../../$SKILLS_DIR/$1" ".claude/skills/$1"
  fi
}

agent_claude_rule() { # name file
  apply_rendered file "$2" ".claude/rules/$1.md"
}

agent_claude_role() { # name file
  local out=$2.claude
  awk '
    /^access: read$/ { print "tools: Read, Grep, Glob"; next }
    /^access: read-run$/ { print "tools: Read, Grep, Glob, Bash"; next }
    /^access: write$/ { print "tools: Read, Grep, Glob, Edit, Write, Bash"; next }
    { print }' "$2" >"$out"
  apply_rendered file "$out" ".claude/agents/$1.md"
}

agent_claude_finish() {
  local out=$HARNESS_TMP/claude.settings.json link=$TARGET/.claude/skills
  if [ -L "$link" ] && [ "$(readlink "$link")" != "../$SKILLS_DIR" ]; then
    ui_warn ".claude/skills links to $(readlink "$link"), so Claude Code will not see the skills in $SKILLS_DIR. Re-run with --force to repoint it."
  fi
  _claude_settings >"$out"
  apply_rendered file "$out" .claude/settings.json
}

# Print a JSON array of the lines on stdin, indented by INDENT.
_claude_json_array() { # indent
  local indent=$1 first=1 line
  printf '['
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [ $first -eq 1 ] || printf ','
    first=0
    printf '\n%s  "%s"' "$indent" "$(json_escape "$line")"
  done
  if [ $first -eq 1 ]; then printf ']'; else printf '\n%s]' "$indent"; fi
}

_claude_allow() {
  settings_list allow_cmd | sed 's/^\(.*\)$/Bash(\1:*)/'
  settings_list allow_tool | while IFS= read -r t; do
    case $t in websearch) echo WebSearch ;; esac
  done
}

# Neutral hook events as Claude's "Event<TAB>matcher<TAB>script<TAB>timeout".
_claude_hooks() {
  local event script timeout
  while IFS="$(printf '\t')" read -r event script timeout; do
    case $event in
      session-start) printf 'SessionStart\t\t%s\t%s\n' "$script" "$timeout" ;;
      pre-shell) printf 'PreToolUse\tBash\t%s\t%s\n' "$script" "$timeout" ;;
      pre-edit) printf 'PreToolUse\tEdit|MultiEdit|Write|NotebookEdit\t%s\t%s\n' "$script" "$timeout" ;;
      post-edit) printf 'PostToolUse\tEdit|MultiEdit|Write\t%s\t%s\n' "$script" "$timeout" ;;
      post-tool) printf 'PostToolUse\t*\t%s\t%s\n' "$script" "$timeout" ;;
      stop) printf 'Stop\t\t%s\t%s\n' "$script" "$timeout" ;;
    esac
  done <"$HARNESS_TMP/settings.hooks"
}

_claude_settings() { # -> stdout
  local hooks=$HARNESS_TMP/claude.hooks event matcher script timeout key value ev_first m_first h_first
  _claude_hooks >"$hooks"
  printf '{\n'
  printf '  "$schema": "https://json.schemastore.org/claude-code-settings.json",\n'
  printf '  "permissions": {\n'
  printf '    "allow": %s,\n' "$(_claude_allow | _claude_json_array '    ')"
  printf '    "ask": %s,\n' "$(settings_list ask_cmd | sed 's/^\(.*\)$/Bash(\1:*)/' | _claude_json_array '    ')"
  printf '    "deny": %s\n' "$({
    settings_list deny_read | sed 's|^\(.*\)$|Read(./\1)|'
    settings_list deny_cmd | sed 's/^\(.*\)$/Bash(\1:*)/'
  } | _claude_json_array '    ')"
  printf '  }'

  awk -F '\t' '$1 == "claude" && $2 == "string" { print $3 "\t" $4 }' "$HARNESS_TMP/settings.agent" |
    while IFS="$(printf '\t')" read -r key value; do
      printf ',\n  "%s": "%s"' "$(json_escape "$key")" "$(json_escape "$value")"
    done

  if grep -q "^claude	env	" "$HARNESS_TMP/settings.agent"; then
    printf ',\n  "env": {'
    ev_first=1
    while IFS="$(printf '\t')" read -r key value; do
      [ $ev_first -eq 1 ] || printf ','
      ev_first=0
      printf '\n    "%s": "%s"' "$(json_escape "$key")" "$(json_escape "$value")"
    done < <(awk -F '\t' '$1 == "claude" && $2 == "env" { print $3 "\t" $4 }' "$HARNESS_TMP/settings.agent")
    printf '\n  }'
  fi

  if [ -s "$hooks" ]; then
    printf ',\n  "hooks": {'
    ev_first=1
    for event in SessionStart PreToolUse PostToolUse Stop; do
      grep -q "^$event	" "$hooks" || continue
      [ $ev_first -eq 1 ] || printf ','
      ev_first=0
      printf '\n    "%s": [' "$event"
      m_first=1
      while IFS= read -r matcher; do
        [ $m_first -eq 1 ] || printf ','
        m_first=0
        printf '\n      {\n'
        [ -z "$matcher" ] || printf '        "matcher": "%s",\n' "$(json_escape "$matcher")"
        printf '        "hooks": ['
        h_first=1
        # Tab is IFS whitespace, so empty fields would collapse: let awk pick
        # the two (always non-empty) columns we need.
        while IFS="$(printf '\t')" read -r script timeout; do
          [ $h_first -eq 1 ] || printf ','
          h_first=0
          printf '\n          {\n'
          printf '            "type": "command",\n'
          printf '            "command": "\\"$CLAUDE_PROJECT_DIR\\"/%s/%s claude",\n' "$HOOKS_DIR" "$(json_escape "$script")"
          printf '            "timeout": %s\n' "$timeout"
          printf '          }'
        done < <(awk -F '\t' -v e="$event" -v m="$matcher" '$1 == e && $2 == m { print $3 "\t" $4 }' "$hooks")
        printf '\n        ]\n      }'
      done < <(awk -F '\t' -v e="$event" '$1 == e && !seen[$2]++ { print $2 }' "$hooks")
      printf '\n    ]'
    done
    printf '\n  }'
  fi
  printf '\n}\n'
}
