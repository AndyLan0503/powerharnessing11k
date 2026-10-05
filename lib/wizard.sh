# shellcheck shell=bash
# The interactive configuration wizard (`harness configure`). Every question
# can be answered with one key; (r) restarts, (q) quits without changes.

WIZ_TOTAL=10

wizard_run() {
  local rc
  # Snapshot the starting answers (detection plus command-line flags) so that
  # a restart (r) keeps them when the stack is unchanged.
  WIZ_PREV_STACK=$HV_STACK WIZ_PREV_PM=$HV_PKG_MANAGER WIZ_PREV_INSTALL=$HV_INSTALL_CMD
  WIZ_PREV_LINT=$HV_LINT_CMD WIZ_PREV_TYPECHECK=$HV_TYPECHECK_CMD WIZ_PREV_TEST=$HV_TEST_CMD
  WIZ_PREV_FULL_TEST=$HV_FULL_TEST_CMD WIZ_PREV_FORMAT=$HV_FORMAT_CMD
  WIZ_PREV_PROFILE=${HV_PROFILE:-software}
  while :; do
    rc=0
    _wizard_steps || rc=$?
    [ $rc -eq 10 ] || return $rc
  done
}

_wizard_steps() {
  local current detected stacks s i opts p
  current=$WIZ_PREV_STACK
  detected=$(detect_stack "$TARGET")

  # 1. Profile ---------------------------------------------------------------
  opts=()
  for p in $ALL_PROFILES; do
    d=$(profile_field "$p" DESC)
    [ "$p" != "$WIZ_PREV_PROFILE" ] || d="$d  ← default"
    opts+=("$(profile_field "$p" TITLE)|$d")
  done
  ui_choose "What is this repository for?" 1 $WIZ_TOTAL "${opts[@]}" || return
  i=0
  for p in $ALL_PROFILES; do
    i=$((i + 1))
    [ $i -ne "$UI_CHOICE" ] || HV_PROFILE=$p
  done
  export HV_PROFILE

  # 2. Stack -----------------------------------------------------------------
  stacks="node python go rust generic"
  opts=()
  for s in $stacks; do
    case $s in
      node) d="JavaScript / TypeScript (npm, pnpm, yarn, bun)" ;;
      python) d="Python (uv, poetry, pip)" ;;
      go) d="Go modules" ;;
      rust) d="Rust / Cargo" ;;
      generic) d="Anything else; fill in commands yourself" ;;
    esac
    # Mark the starting answer only when something chose it: the repo's files
    # or --stack. An empty folder detects nothing, so nothing is marked.
    if [ "$s" = "$current" ]; then
      if [ "$s" != "$detected" ]; then
        d="$d  ← from --stack"
      elif [ "$s" != generic ]; then
        d="$d  ← detected"
      fi
    fi
    opts+=("$s|$d")
  done
  ui_choose "What language or toolchain does it use?" 2 $WIZ_TOTAL "${opts[@]}" || return
  i=0
  for s in $stacks; do
    i=$((i + 1))
    [ $i -ne "$UI_CHOICE" ] || HV_STACK=$s
  done
  if [ "$HV_STACK" = "$WIZ_PREV_STACK" ]; then
    HV_PKG_MANAGER=$WIZ_PREV_PM HV_INSTALL_CMD=$WIZ_PREV_INSTALL HV_LINT_CMD=$WIZ_PREV_LINT
    HV_TYPECHECK_CMD=$WIZ_PREV_TYPECHECK HV_TEST_CMD=$WIZ_PREV_TEST
    HV_FULL_TEST_CMD=$WIZ_PREV_FULL_TEST HV_FORMAT_CMD=$WIZ_PREV_FORMAT
    export HV_INSTALL_CMD HV_LINT_CMD HV_TYPECHECK_CMD HV_TEST_CMD HV_FULL_TEST_CMD HV_FORMAT_CMD
  else
    HV_PKG_MANAGER=$(detect_pkg_manager "$TARGET" "$HV_STACK")
    stack_defaults
  fi
  export HV_STACK HV_PKG_MANAGER

  # 3. Commands --------------------------------------------------------------
  local evals='' nl=$'\n' cmds
  case $HV_PROFILE in ml | agentic) evals=1 ;; esac
  cmds="install     ${HV_INSTALL_CMD:-—}${nl}lint        ${HV_LINT_CMD:-—}${nl}typecheck   ${HV_TYPECHECK_CMD:-—}"
  cmds="$cmds${nl}test        ${HV_TEST_CMD:-—}${nl}full tests  ${HV_FULL_TEST_CMD:-—}${nl}format      ${HV_FORMAT_CMD:-—}"
  [ -z "$evals" ] || cmds="$cmds${nl}eval        ${HV_EVAL_CMD:-—}"
  ui_choose "These commands will be used by hooks, CI, and agent docs. OK?" 3 $WIZ_TOTAL \
    "Use them|$cmds" \
    "Edit them|Type each command; Enter keeps the default, '-' clears it" || return
  if [ "$UI_CHOICE" = 2 ]; then
    ui_header 3 $WIZ_TOTAL "Edit commands"
    ui_note "Enter keeps the default shown in brackets. '-' clears a command."
    ui_note "The format command may use {file} for the edited file's path."
    printf '\n'
    _wizard_edit INSTALL_CMD "Install  "
    _wizard_edit LINT_CMD "Lint     "
    _wizard_edit TYPECHECK_CMD "Typecheck"
    _wizard_edit TEST_CMD "Test     "
    ui_note "Full tests: the slow tier (regression, benchmarks), run nightly. Leave empty if there is none."
    _wizard_edit FULL_TEST_CMD "Full test"
    _wizard_edit FORMAT_CMD "Format   "
    [ -z "$evals" ] || _wizard_edit EVAL_CMD "Eval     "
  fi

  # 4. Agent tools -----------------------------------------------------------
  ui_choose "Which coding agents will work in this repo?" 4 $WIZ_TOTAL \
    "Claude Code only|All agent guidance lives in CLAUDE.md" \
    "Claude Code + others (Copilot, Codex, Cursor...)|Shared guidance in AGENTS.md; CLAUDE.md imports it with @AGENTS.md" || return
  if [ "$UI_CHOICE" = 1 ]; then HV_AGENT_TOOLS=claude; else HV_AGENT_TOOLS=multi; fi
  export HV_AGENT_TOOLS

  # 5. Tier -----------------------------------------------------------------
  local title
  title=$(profile_field "$HV_PROFILE" TITLE)
  ui_choose "How much harness for this $title repo?" 5 $WIZ_TOTAL \
    "Minimal|$(profile_field "$HV_PROFILE" MINIMAL)  (guard: relaxed)" \
    "Recommended|$(profile_field "$HV_PROFILE" RECOMMENDED)  (guard: $(profile_field "$HV_PROFILE" GUARD_LEVEL))" \
    "Strict|$(profile_field "$HV_PROFILE" STRICT)  (guard: $(profile_field "$HV_PROFILE" STRICT_GUARD))" \
    "Custom|Pick modules and guard level one by one" || return
  case $UI_CHOICE in
    1) profile_load "$HV_PROFILE" minimal ;;
    2) profile_load "$HV_PROFILE" recommended ;;
    3) profile_load "$HV_PROFILE" strict ;;
    4) _wizard_custom || return ;;
  esac

  # 6. Artifacts -------------------------------------------------------------
  local art_yes="Yes|Local data/ and models/, pinned by hash in artifacts.lock; no cloud needed"
  local art_no="No|No data or model files to version"
  if list_has "$HV_MODULES" artifacts; then
    art_yes="$art_yes  ← profile default"
  else
    art_no="$art_no  ← profile default"
  fi
  ui_choose "Does this project version data or model files?" 6 $WIZ_TOTAL "$art_yes" "$art_no" || return
  if [ "$UI_CHOICE" = 1 ]; then
    HV_MODULES=$(modules_normalize "$HV_MODULES artifacts")
  else
    HV_MODULES=$(printf ' %s ' "$HV_MODULES" | sed 's/ artifacts / /g')
  fi
  export HV_MODULES

  # 7. Project-specific stubs ---------------------------------------------------
  ui_choose "Create blank, project-specific files for the team to fill in?" 7 $WIZ_TOTAL \
    "No|Skip; add skills, subagents, and rules later by hand" \
    "Yes|Name them now (e.g. a solver skill, a model-validation rule); each gets a TODO(team) stub" || return
  if [ "$UI_CHOICE" = 2 ]; then
    _wizard_stubs || return
  else
    HV_SKILLS='' HV_ROLES='' HV_RULES='' HV_DIRS=''
    export HV_SKILLS HV_ROLES HV_RULES HV_DIRS
  fi

  # 8. Code owners -----------------------------------------------------------
  if list_has "$HV_MODULES" collab; then
    ui_header 8 $WIZ_TOTAL "Who must review changes? (CODEOWNERS)"
    ui_note "GitHub users or teams, space-separated, e.g. @acme/platform @alice."
    ui_note "Leave empty to skip CODEOWNERS."
    printf '\n'
    ui_line "Owners" "${HV_CODEOWNERS:-$(_default_owner)}"
    HV_CODEOWNERS=$UI_LINE
    [ "$HV_CODEOWNERS" != "-" ] || HV_CODEOWNERS=''
    export HV_CODEOWNERS
  fi

  # 9. Telemetry -------------------------------------------------------------
  ui_choose "Export Claude Code telemetry (cost, tokens, sessions) via OpenTelemetry?" 9 $WIZ_TOTAL \
    "No|You still get the local audit log and CI agent monitoring" \
    "Yes|Send metrics to an OTLP collector (Grafana, Datadog, Honeycomb, ...)" || return
  if [ "$UI_CHOICE" = 2 ]; then
    ui_header 9 $WIZ_TOTAL "OTLP collector endpoint"
    ui_note "gRPC endpoint. Auth headers stay out of git (see docs/agents/TELEMETRY.md)."
    printf '\n'
    ui_line "Endpoint" "${HV_OTEL_ENDPOINT:-http://localhost:4317}"
    HV_OTEL_ENDPOINT=$UI_LINE
    HV_MODULES=$(modules_normalize "$HV_MODULES telemetry")
  else
    HV_OTEL_ENDPOINT=''
  fi
  export HV_OTEL_ENDPOINT HV_MODULES

  # 10. Confirm ---------------------------------------------------------------
  derive_vars
  while :; do
    ui_header 10 $WIZ_TOTAL "Ready to apply"
    _wizard_summary
    printf '  %s  Apply to %s\n' "${C_ACCENT}${C_BOLD}(y)${C_RESET}" "${C_BOLD}$TARGET${C_RESET}"
    ui_footer
    printf '  %s ' "${C_BOLD}Choice [yrq]:${C_RESET}"
    ui_key
    printf '\n'
    case $UI_KEY in
      y | Y) return 0 ;;
      r | R) return 10 ;;
      q | Q | n | N) ui_quit ;;
    esac
  done
}

_wizard_edit() { # KEY label
  local var="HV_$1"
  ui_line "$2" "${!var:-}"
  [ "$UI_LINE" != "-" ] || UI_LINE=''
  printf -v "$var" '%s' "$UI_LINE"
  export "${var?}"
}

_wizard_custom() {
  local m rc picked='core'
  for m in $ALL_MODULES; do
    [ "$m" != core ] || continue
    [ "$m" != telemetry ] || continue # asked separately
    [ "$m" != artifacts ] || continue # asked separately
    # Profile modules: the selected profile's own is always in, others never.
    if list_has "$ALL_PROFILES" "$m"; then
      [ "$m" != "$HV_PROFILE" ] || picked="$picked $m"
      continue
    fi
    rc=0
    ui_yesno "Custom modules" 5 $WIZ_TOTAL "Include ${C_BOLD}$m${C_RESET}?  ${C_DIM}$(module_desc "$m")${C_RESET}" || rc=$?
    case $rc in
      0) picked="$picked $m" ;;
      10) return 10 ;;
    esac
  done
  HV_MODULES=$picked
  ui_choose "Guard level for hooks and CI" 5 $WIZ_TOTAL \
    "Relaxed|Block only catastrophic actions (rm -rf ~, pushing to the default branch)" \
    "Standard|Also block force-push, --no-verify, curl|sh, secret access; lint before finishing" \
    "Strict|Also make CI/guardrail files human-only; agent-guard findings block merges" || return
  case $UI_CHOICE in
    1) HV_GUARD_LEVEL=relaxed ;;
    2) HV_GUARD_LEVEL=standard ;;
    3) HV_GUARD_LEVEL=strict ;;
  esac
  export HV_MODULES HV_GUARD_LEVEL
}

_wizard_stubs() {
  local err
  while :; do
    ui_header 7 $WIZ_TOTAL "Project-specific stubs"
    ui_note "Space-separated; leave empty for none. Names: lowercase letters, digits, hyphens."
    ui_note "Each file is created blank, with TODO(team) notes on what to write."
    printf '\n'
    ui_note "Skills (.claude/skills/<name>/SKILL.md), e.g. run-solver"
    ui_line "Skills  " "${HV_SKILLS:--}"
    HV_SKILLS=$UI_LINE
    ui_note "Subagents (.claude/agents/<name>.md), e.g. model-checker"
    ui_line "Roles   " "${HV_ROLES:--}"
    HV_ROLES=$UI_LINE
    ui_note "Path-scoped rules (.claude/rules/<name>.md) as name=glob[,glob], e.g. solver=src/*/solver/**"
    ui_line "Rules   " "${HV_RULES:--}"
    HV_RULES=$UI_LINE
    ui_note "Directories that get a README stub, e.g. src/app/model experiments"
    ui_line "Dirs    " "${HV_DIRS:--}"
    HV_DIRS=$UI_LINE
    [ "$HV_SKILLS" != "-" ] || HV_SKILLS=''
    [ "$HV_ROLES" != "-" ] || HV_ROLES=''
    [ "$HV_RULES" != "-" ] || HV_RULES=''
    [ "$HV_DIRS" != "-" ] || HV_DIRS=''
    HV_SKILLS=${HV_SKILLS//,/ } HV_ROLES=${HV_ROLES//,/ } HV_DIRS=${HV_DIRS//,/ }
    export HV_SKILLS HV_ROLES HV_RULES HV_DIRS
    if err=$(custom_validate 2>&1); then
      return 0
    fi
    printf '\n'
    ui_warn "${err#"$HARNESS_NAME": }"
    ui_note "Press any key to try again."
    ui_key
  done
}

_default_owner() {
  local url owner
  url=$(git -C "$TARGET" remote get-url origin 2>/dev/null) || return 0
  owner=${url%/*}
  owner=${owner##*[:/]}
  [ -z "$owner" ] || printf '@%s' "$owner"
}

_wizard_summary() {
  local m
  ui_info "${C_BOLD}Profile${C_RESET}      $(profile_field "$HV_PROFILE" TITLE)"
  ui_info "${C_BOLD}Project${C_RESET}      $HV_PROJECT_NAME  ${C_DIM}($HV_STACK, $HV_PKG_MANAGER, default branch $HV_DEFAULT_BRANCH)${C_RESET}"
  ui_info "${C_BOLD}Agents${C_RESET}       $([ "$HV_AGENT_TOOLS" = multi ] && echo 'Claude Code + others (AGENTS.md)' || echo 'Claude Code (CLAUDE.md)')"
  ui_info "${C_BOLD}Guard level${C_RESET}  $HV_GUARD_LEVEL"
  [ -z "$HV_CODEOWNERS" ] || ui_info "${C_BOLD}Owners${C_RESET}       $HV_CODEOWNERS"
  [ -z "$HV_OTEL_ENDPOINT" ] || ui_info "${C_BOLD}Telemetry${C_RESET}    $HV_OTEL_ENDPOINT"
  [ -z "$HV_SKILLS" ] || ui_info "${C_BOLD}Skills${C_RESET}       $HV_SKILLS"
  [ -z "$HV_ROLES" ] || ui_info "${C_BOLD}Roles${C_RESET}        $HV_ROLES"
  [ -z "$HV_RULES" ] || ui_info "${C_BOLD}Rules${C_RESET}        $HV_RULES"
  [ -z "$HV_DIRS" ] || ui_info "${C_BOLD}Dirs${C_RESET}         $HV_DIRS"
  printf '\n'
  for m in $HV_MODULES; do
    printf '  %s %-12s %s\n' "${C_OK}●${C_RESET}" "$m" "${C_DIM}$(module_desc "$m")${C_RESET}"
  done
  printf '\n'
  if [ -n "${FORCE:-}" ]; then
    ui_note "--force: existing files with the same paths will be overwritten."
  else
    ui_note "Existing files are never overwritten; only missing ones are created."
  fi
  ui_note "After this, every file belongs to the team; $HARNESS_NAME is not needed again."
  printf '\n'
}
