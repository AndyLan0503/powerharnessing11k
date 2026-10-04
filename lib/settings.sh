# shellcheck shell=bash
# Modules contribute to .claude/settings.json through these calls; the file is
# generated once all modules have run. Team-specific extra rules live in
# .harness/permissions ("allow|deny|ask <rule>" per line) and survive updates.

settings_reset() {
  local f
  for f in allow deny ask env hooks; do : >"$HARNESS_TMP/settings.$f"; done
}

settings_allow() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.allow"; }
settings_deny() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.deny"; }
settings_ask() { printf '%s\n' "$@" >>"$HARNESS_TMP/settings.ask"; }
settings_env() { printf '%s\t%s\n' "$1" "$2" >>"$HARNESS_TMP/settings.env"; }

# settings_hook EVENT MATCHER SCRIPT [TIMEOUT_SECONDS]
# SCRIPT is a file name under .claude/hooks/. MATCHER may be empty.
settings_hook() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-30}" >>"$HARNESS_TMP/settings.hooks"
}

_settings_extra() {
  local file=$TARGET/.harness/permissions kind rule line
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in '' | '#'*) continue ;; esac
    kind=${line%% *}
    rule=$(trim "${line#* }")
    case $kind in
      allow | deny | ask) printf '%s\n' "$rule" >>"$HARNESS_TMP/settings.$kind" ;;
    esac
  done <"$file"
}

# Print a JSON array of the unique lines in FILE, indented by INDENT.
_json_array() {
  local file=$1 indent=$2 first=1 line
  if [ ! -s "$file" ]; then
    printf '[]'
    return
  fi
  printf '['
  while IFS= read -r line; do
    [ $first -eq 1 ] || printf ','
    first=0
    printf '\n%s  "%s"' "$indent" "$(json_escape "$line")"
  done < <(awk '!seen[$0]++' "$file")
  printf '\n%s]' "$indent"
}

settings_render() { # -> stdout
  local event matcher script timeout key value ev_first m_first h_first
  _settings_extra
  printf '{\n'
  printf '  "$schema": "https://json.schemastore.org/claude-code-settings.json",\n'
  printf '  "permissions": {\n'
  printf '    "allow": %s,\n' "$(_json_array "$HARNESS_TMP/settings.allow" '    ')"
  printf '    "ask": %s,\n' "$(_json_array "$HARNESS_TMP/settings.ask" '    ')"
  printf '    "deny": %s\n' "$(_json_array "$HARNESS_TMP/settings.deny" '    ')"
  printf '  }'

  if [ -s "$HARNESS_TMP/settings.env" ]; then
    printf ',\n  "env": {'
    ev_first=1
    while IFS="$(printf '\t')" read -r key value; do
      [ $ev_first -eq 1 ] || printf ','
      ev_first=0
      printf '\n    "%s": "%s"' "$(json_escape "$key")" "$(json_escape "$value")"
    done <"$HARNESS_TMP/settings.env"
    printf '\n  }'
  fi

  if [ -s "$HARNESS_TMP/settings.hooks" ]; then
    printf ',\n  "hooks": {'
    ev_first=1
    for event in SessionStart UserPromptSubmit PreToolUse PostToolUse Stop SubagentStop; do
      grep -q "^$event	" "$HARNESS_TMP/settings.hooks" || continue
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
          printf '            "command": "\\"$CLAUDE_PROJECT_DIR\\"/.claude/hooks/%s",\n' "$(json_escape "$script")"
          printf '            "timeout": %s\n' "$timeout"
          printf '          }'
        done < <(awk -F '\t' -v e="$event" -v m="$matcher" '$1 == e && $2 == m { print $3 "\t" $4 }' "$HARNESS_TMP/settings.hooks")
        printf '\n        ]\n      }'
      done < <(awk -F '\t' -v e="$event" '$1 == e && !seen[$2]++ { print $2 }' "$HARNESS_TMP/settings.hooks")
      printf '\n    ]'
    done
    printf '\n  }'
  fi
  printf '\n}\n'
}
