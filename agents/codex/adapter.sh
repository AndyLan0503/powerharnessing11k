# shellcheck shell=bash
# OpenAI Codex CLI adapter. Formats follow the Codex docs and source
# (github.com/openai/codex, codex-rs/hooks, config, execpolicy, agent-roles).
#   instructions  AGENTS.md, read natively
#   rules         no path scoping: routed into AGENTS.md (always loaded)
#   skills        .agents/skills/, read natively
#   roles         .codex/agents/<name>.toml, access translated to a sandbox mode
#   settings      .codex/config.toml   approval policy, sandbox, MCP servers
#                 .codex/rules/default.rules   allowed, prompted, forbidden commands
#                 .codex/hooks.json    hook wiring (same events and payloads as
#                                      Claude Code; edits arrive as apply_patch)
# Codex loads .codex/ only for a trusted project, and runs a project hook only
# after the user has reviewed it with /hooks.
AGENT_TITLE="Codex CLI"
# shellcheck disable=SC2034 # read by lib/agents.sh
AGENT_LAYOUT='Codex CLI: reads this file directly; `.codex/config.toml` (approvals, sandbox, MCP servers), `.codex/rules/default.rules` (command rules), `.codex/hooks.json` (hook wiring), `.codex/agents/` (subagents).'
# shellcheck disable=SC2034
AGENT_OWNED=".codex/"
# shellcheck disable=SC2034
AGENT_PROTECTED=".codex/config.toml .codex/hooks.json .codex/rules/default.rules"
# shellcheck disable=SC2034
AGENT_COVERAGE="always loaded (inside AGENTS.md)|a sandbox level per role|prompt and forbid rules; other commands run inside the sandbox; no per-file read rules|lint and typecheck must pass"
# shellcheck disable=SC2034
AGENT_NEXT_STEP="Codex CLI: open the repo with codex, trust the project, then run /hooks and approve the hooks (Codex skips project hooks until you do, and again whenever they change)"

agent_codex_begin() { :; }
agent_codex_skill() { :; }

agent_codex_rule() { # name file
  agents_md_rule "$1" "$2"
}

# TOML basic-string escaping for one line of text.
_codex_toml_str() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

agent_codex_role() { # name file
  local name=$1 file=$2 out=$2.codex desc access sandbox
  desc=$(awk '/^description: / { sub(/^description: */, ""); print; exit }' "$file")
  # A quoted YAML description: drop the quotes and their escapes, keep the text.
  case $desc in
    '"'*'"') desc=${desc#\"} desc=${desc%\"} desc=${desc//\\\"/\"} ;;
    "'"*"'") desc=${desc#\'} desc=${desc%\'} desc=${desc//\'\'/\'} ;;
  esac
  access=$(awk '/^access: / { print $2; exit }' "$file")
  case $access in
    write) sandbox=workspace-write ;;
    *) sandbox=read-only ;;
  esac
  {
    printf 'name = "%s"\n' "$(printf '%s' "$name" | tr '-' '_')"
    printf 'description = "%s"\n' "$(_codex_toml_str "$desc")"
    printf 'sandbox_mode = "%s"\n' "$sandbox"
    printf 'developer_instructions = """\n'
    # The body after the frontmatter, escaped for a TOML multi-line string:
    # backslashes doubled, and a run of three quotes broken up. sed does the
    # escaping because awk implementations disagree about "\\" in gsub.
    awk '
      NR == 1 && /^---$/ { infm = 1; next }
      infm && /^---$/ { infm = 0; started = 0; next }
      infm { next }
      !started && /^[[:space:]]*$/ { next }
      { started = 1; print }' "$file" | sed 's/\\/\\\\/g; s/"""/""\\"/g'
    printf '"""\n'
  } >"$out"
  apply_rendered file "$out" ".codex/agents/$name.toml"
}

agent_codex_finish() {
  _codex_config >"$HARNESS_TMP/codex.config.toml"
  apply_rendered file "$HARNESS_TMP/codex.config.toml" .codex/config.toml
  _codex_rules >"$HARNESS_TMP/codex.rules"
  apply_rendered file "$HARNESS_TMP/codex.rules" .codex/rules/default.rules
  if [ -s "$HARNESS_TMP/settings.hooks" ]; then
    _codex_hooks >"$HARNESS_TMP/codex.hooks.json"
    apply_rendered file "$HARNESS_TMP/codex.hooks.json" .codex/hooks.json
  fi
}

_codex_config() { # -> stdout
  local name url token
  cat <<'TOML'
# Project settings for Codex CLI. Loaded only when the project is trusted.
# Reference: https://developers.openai.com/codex/config-reference

# Ask before anything the sandbox does not already allow.
approval_policy = "on-request"
# Read anywhere, write only inside this repository, no network by default.
sandbox_mode = "workspace-write"
TOML
  while IFS="$(printf '\t')" read -r name url token; do
    printf '\n[mcp_servers.%s]\nurl = "%s"\nbearer_token_env_var = "%s"\n' \
      "$(printf '%s' "$name" | tr -c 'A-Za-z0-9_\n-' '_')" "$(_codex_toml_str "$url")" "$token"
  done <"$HARNESS_TMP/settings.mcp"
}

# A command prefix as a Starlark list, or nothing when it cannot be one
# (shell operators, quotes, and the like have no meaning in a prefix rule).
_codex_pattern() { # command
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._/=:@+-]+( [A-Za-z0-9._/=:@+-]+)*$' || return 1
  printf '%s' "$1" | awk '{ out = ""; for (i = 1; i <= NF; i++) out = out (i > 1 ? ", " : "") "\"" $i "\""; printf "[%s]", out }'
}

_codex_rules() { # -> stdout
  local kind decision cmd pattern skipped=''
  cat <<'RULES'
# Command rules for Codex CLI (Starlark). Each rule matches a command prefix.
# Test a rule file:  codex execpolicy check --pretty --rules .codex/rules/default.rules -- <command>
#
# Only "forbidden" and "prompt" rules are written here. Everything else runs
# inside the sandbox set in config.toml without a prompt, which is what an
# allow-list is for; an explicit "allow" rule could instead let a command run
# outside the sandbox, so none is written.
RULES
  for kind in deny_cmd ask_cmd; do
    case $kind in
      deny_cmd) decision=forbidden ;;
      *) decision=prompt ;;
    esac
    while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      if pattern=$(_codex_pattern "$cmd"); then
        printf '\nprefix_rule(\n    pattern = %s,\n    decision = "%s",\n' "$pattern" "$decision"
        [ "$decision" != forbidden ] || printf '    justification = "blocked by this repository'"'"'s guardrails; ask a human if it is truly needed",\n'
        printf ')\n'
      else
        skipped="$skipped
#   $decision: $cmd"
      fi
    done < <(settings_list "$kind")
  done
  if [ -n "$skipped" ]; then
    printf '\n# These use shell syntax and cannot be written as a prefix rule, so this\n# file does not enforce them. The guard hook in .agents/hooks/ still applies.%s\n' "$skipped"
  fi
}

# Neutral hook events as "Event<TAB>matcher<TAB>script<TAB>timeout". Codex has
# no cloud session-start use for the install hook, so that event is skipped.
_codex_hook_rows() {
  local event script timeout
  while IFS="$(printf '\t')" read -r event script timeout; do
    case $event in
      pre-shell) printf 'PreToolUse\tBash\t%s\t%s\n' "$script" "$timeout" ;;
      pre-edit) printf 'PreToolUse\tapply_patch\t%s\t%s\n' "$script" "$timeout" ;;
      post-edit) printf 'PostToolUse\tapply_patch\t%s\t%s\n' "$script" "$timeout" ;;
      post-tool) printf 'PostToolUse\t\t%s\t%s\n' "$script" "$timeout" ;;
      stop) printf 'Stop\t\t%s\t%s\n' "$script" "$timeout" ;;
    esac
  done <"$HARNESS_TMP/settings.hooks"
}

_codex_hooks() { # -> stdout
  local rows=$HARNESS_TMP/codex.hooks event matcher script timeout ev_first m_first h_first
  _codex_hook_rows >"$rows"
  printf '{\n  "description": "Guard, format, check, and audit hooks shared by every coding agent in this repository.",\n  "hooks": {'
  ev_first=1
  for event in PreToolUse PostToolUse Stop; do
    grep -q "^$event	" "$rows" || continue
    [ $ev_first -eq 1 ] || printf ','
    ev_first=0
    printf '\n    "%s": [' "$event"
    m_first=1
    while IFS= read -r matcher; do
      [ $m_first -eq 1 ] || printf ','
      m_first=0
      printf '\n      {\n'
      [ "$matcher" = - ] || printf '        "matcher": "%s",\n' "$matcher"
      printf '        "hooks": ['
      h_first=1
      while IFS="$(printf '\t')" read -r script timeout; do
        [ $h_first -eq 1 ] || printf ','
        h_first=0
        printf '\n          {\n'
        printf '            "type": "command",\n'
        # Hooks run through a shell in the session directory, which may be a
        # subdirectory; find the repository root the way the Codex docs do.
        printf '            "command": "\\"$(git rev-parse --show-toplevel)/%s/%s\\" codex",\n' "$HOOKS_DIR" "$(json_escape "$script")"
        printf '            "timeout": %s\n' "$timeout"
        printf '          }'
      done < <(awk -F '\t' -v e="$event" -v m="$matcher" '$1 == e && ($2 == "" ? "-" : $2) == m { print $3 "\t" $4 }' "$rows")
      printf '\n        ]\n      }'
    done < <(awk -F '\t' -v e="$event" '$1 == e { m = ($2 == "" ? "-" : $2); if (!seen[m]++) print m }' "$rows")
    printf '\n    ]'
  done
  printf '\n  }\n}\n'
}
