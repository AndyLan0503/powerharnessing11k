# shellcheck shell=bash
# GitHub Copilot adapter (Copilot CLI, the cloud agent, and IDE agent mode).
# Formats follow docs.github.com/en/copilot (hooks reference, custom agents
# configuration, repository custom instructions).
#   instructions  AGENTS.md, read natively by the CLI, the cloud agent, code
#                 review, and VS Code; .github/copilot-instructions.md points
#                 the remaining IDEs at it
#   rules         .github/instructions/<name>.instructions.md with applyTo
#   skills        .agents/skills/, read natively
#   roles         .github/agents/<name>.agent.md, access translated to tool aliases
#   settings      .github/hooks/guardrails.json   hook wiring
#                 .github/mcp.json                team MCP servers (CLI)
# Copilot has no repository-level file for allowing or denying commands, so
# the guard hooks are the only enforcement.
AGENT_TITLE="GitHub Copilot"
# shellcheck disable=SC2034 # read by lib/agents.sh
AGENT_LAYOUT='GitHub Copilot: reads this file directly; `.github/instructions/` (path-scoped rules), `.github/agents/` (custom agents), `.github/hooks/guardrails.json` (hook wiring), `.github/mcp.json` (MCP servers for the CLI), `.github/copilot-instructions.md` (a pointer to this file).'
# .github/ as a whole already has an owner in CODEOWNERS.
# shellcheck disable=SC2034
AGENT_OWNED=""
# Copilot loads every file in .github/hooks/, so the whole folder is protected.
# shellcheck disable=SC2034
AGENT_PROTECTED=".github/hooks/*"
# shellcheck disable=SC2034
AGENT_COVERAGE="loaded only for matching paths|a tool list per agent|none at repository level: the guard hooks do the blocking, and nothing is pre-approved|lint and typecheck must pass (CLI and cloud agent)"
# shellcheck disable=SC2034
AGENT_NEXT_STEP="GitHub Copilot: the CLI loads the hooks once you trust the folder; the cloud agent uses the hooks, agents, and instructions on the default branch, so they apply after this change is merged. Team MCP servers for the cloud agent are set in the repository's Copilot settings"

agent_copilot_begin() {
  emit file copilot-instructions.md .github/copilot-instructions.md
}

agent_copilot_skill() { :; }

agent_copilot_rule() { # name file
  local out=$2.copilot
  # paths: ["a", "b"]  ->  applyTo: "a,b"
  awk '
    NR == 2 && /^paths: / {
      g = $0
      sub(/^paths: *\[/, "", g); sub(/\] *$/, "", g)
      gsub(/", *"/, ",", g); gsub(/"/, "", g)
      printf "applyTo: \"%s\"\n", g
      next
    }
    { print }' "$2" >"$out"
  apply_rendered file "$out" ".github/instructions/$1.instructions.md"
}

agent_copilot_role() { # name file
  local out=$2.copilot
  awk '
    /^access: read$/ { print "tools: [\"read\", \"search\"]"; next }
    /^access: read-run$/ { print "tools: [\"read\", \"search\", \"execute\"]"; next }
    /^access: write$/ { print "tools: [\"read\", \"search\", \"edit\", \"execute\"]"; next }
    { print }' "$2" >"$out"
  apply_rendered file "$out" ".github/agents/$1.agent.md"
}

agent_copilot_finish() {
  if [ -s "$HARNESS_TMP/settings.hooks" ]; then
    _copilot_hooks >"$HARNESS_TMP/copilot.hooks.json"
    apply_rendered file "$HARNESS_TMP/copilot.hooks.json" .github/hooks/guardrails.json
  fi
  if [ -s "$HARNESS_TMP/settings.mcp" ]; then
    _copilot_mcp >"$HARNESS_TMP/copilot.mcp.json"
    apply_rendered file "$HARNESS_TMP/copilot.mcp.json" .github/mcp.json
  fi
}

# Neutral hook events as "event<TAB>matcher<TAB>script<TAB>timeout". The
# matcher is a regex over Copilot's tool names; "-" means every tool.
# Session start is skipped: Copilot's cloud agent prepares its environment
# through its own setup-steps workflow.
_copilot_hook_rows() {
  local event script timeout
  while IFS="$(printf '\t')" read -r event script timeout; do
    case $event in
      pre-shell) printf 'preToolUse\tbash|powershell\t%s\t%s\n' "$script" "$timeout" ;;
      pre-edit) printf 'preToolUse\tcreate|edit|str_replace_editor|apply_patch\t%s\t%s\n' "$script" "$timeout" ;;
      post-edit) printf 'postToolUse\tcreate|edit|str_replace_editor|apply_patch\t%s\t%s\n' "$script" "$timeout" ;;
      post-tool) printf 'postToolUse\t-\t%s\t%s\n' "$script" "$timeout" ;;
      stop) printf 'agentStop\t-\t%s\t%s\n' "$script" "$timeout" ;;
    esac
  done <"$HARNESS_TMP/settings.hooks"
}

_copilot_hooks() { # -> stdout
  local rows=$HARNESS_TMP/copilot.hooks event matcher script timeout ev_first h_first
  _copilot_hook_rows >"$rows"
  printf '{\n  "version": 1,\n  "hooks": {'
  ev_first=1
  for event in preToolUse postToolUse agentStop; do
    grep -q "^$event	" "$rows" || continue
    [ $ev_first -eq 1 ] || printf ','
    ev_first=0
    printf '\n    "%s": [' "$event"
    h_first=1
    while IFS="$(printf '\t')" read -r matcher script timeout; do
      [ $h_first -eq 1 ] || printf ','
      h_first=0
      printf '\n      {\n'
      printf '        "type": "command",\n'
      [ "$matcher" = - ] || printf '        "matcher": "%s",\n' "$matcher"
      # Hook commands run from the repository root.
      printf '        "bash": "%s/%s copilot",\n' "$HOOKS_DIR" "$(json_escape "$script")"
      printf '        "cwd": ".",\n'
      printf '        "timeoutSec": %s\n' "$timeout"
      printf '      }'
    done < <(awk -F '\t' -v e="$event" '$1 == e { print $2 "\t" $3 "\t" $4 }' "$rows")
    printf '\n    ]'
  done
  printf '\n  }\n}\n'
}

# Team MCP servers for the Copilot CLI. ${VAR} is expanded from the
# environment; "tools" is required and "*" enables all of a server's tools.
_copilot_mcp() { # -> stdout
  local name url token first=1
  printf '{\n  "mcpServers": {'
  while IFS="$(printf '\t')" read -r name url token; do
    [ $first -eq 1 ] || printf ','
    first=0
    printf '\n    "%s": {\n      "type": "http",\n      "url": "%s",\n      "headers": {\n        "Authorization": "Bearer ${%s}"\n      },\n      "tools": ["*"]\n    }' \
      "$(json_escape "$name")" "$(json_escape "$url")" "$token"
  done <"$HARNESS_TMP/settings.mcp"
  printf '\n  }\n}\n'
}
