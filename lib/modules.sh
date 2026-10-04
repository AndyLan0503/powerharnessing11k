# shellcheck shell=bash
# Module registry. A module is modules/<name>/module.sh defining MODULE_DESC
# and module_apply(), which calls emit / settings_* (see lib/apply.sh and
# lib/settings.sh). Order matters only for readability of the summary.

ALL_MODULES="core guardrails quality audit skills ml agentic study research collab ci security agent-guard review telemetry"
ALL_PROFILES="software ml agentic study research"
ALL_TIERS="minimal recommended strict"

module_desc() {
  (
    MODULE_DESC=''
    # shellcheck disable=SC1090
    . "$HARNESS_ROOT/modules/$1/module.sh"
    printf '%s' "$MODULE_DESC"
  )
}

module_run() { # name
  MODULE_NAME=$1
  MODULE_DIR=$HARNESS_ROOT/modules/$1
  export MODULE_DIR
  [ -f "$MODULE_DIR/module.sh" ] || harness_die "unknown module: $1"
  unset -f module_apply
  # shellcheck disable=SC1091
  . "$MODULE_DIR/module.sh"
  module_apply
  unset -f module_apply
}

# Normalise a module list: known modules only, canonical order, core first.
modules_normalize() {
  local want=" core $* " m out=''
  want=${want//,/ }
  for m in $ALL_MODULES; do
    case $want in *" $m "*) out="$out $m" ;; esac
  done
  for m in ${want}; do
    list_has "$ALL_MODULES" "$m" || harness_die "unknown module '$m' (see: harness list)"
  done
  trim "$out"
}

# A profile (profiles/<name>.profile) says what the repo is for; a tier says
# how much harness. Together they choose modules and a guard level.

profile_field() { # profile KEY
  local file=$HARNESS_ROOT/profiles/$1.profile
  [ -f "$file" ] || harness_die "unknown profile '$1' (${ALL_PROFILES// /, })"
  sed -n "s/^$2=//p" "$file" | head -n 1
}

tier_normalize() { # accepts the old preset name "standard" as "recommended"
  case $1 in
    minimal | recommended | strict) printf '%s' "$1" ;;
    standard) printf 'recommended' ;;
    *) harness_die "unknown tier '$1' (minimal, recommended, strict)" ;;
  esac
}

profile_load() { # profile tier -> sets HV_PROFILE HV_MODULES HV_GUARD_LEVEL
  local tier
  tier=$(tier_normalize "$2")
  HV_PROFILE=$1
  case $tier in
    minimal)
      HV_MODULES=$(profile_field "$1" MINIMAL)
      HV_GUARD_LEVEL=relaxed
      ;;
    recommended)
      HV_MODULES=$(profile_field "$1" RECOMMENDED)
      HV_GUARD_LEVEL=$(profile_field "$1" GUARD_LEVEL)
      ;;
    strict)
      HV_MODULES=$(profile_field "$1" STRICT)
      HV_GUARD_LEVEL=$(profile_field "$1" STRICT_GUARD)
      ;;
  esac
  export HV_PROFILE HV_MODULES HV_GUARD_LEVEL
}

# Flags derived from answers, used by templates ({{#if MOD_CI}} etc.).
derive_vars() {
  local m up
  HV_HARNESS_VERSION=$HARNESS_VERSION
  HV_HARNESS_URL=$(harness_url)
  export HV_HARNESS_URL
  HV_MULTI_AGENT=''
  [ "$HV_AGENT_TOOLS" = multi ] && HV_MULTI_AGENT=1
  HV_GUARD_RELAXED='' HV_GUARD_STANDARD='' HV_GUARD_STRICT=''
  case $HV_GUARD_LEVEL in
    relaxed) HV_GUARD_RELAXED=1 ;;
    standard) HV_GUARD_STANDARD=1 ;;
    strict) HV_GUARD_STRICT=1 ;;
  esac
  export HV_GUARD_RELAXED HV_GUARD_STANDARD
  HV_AGENT_GUARD_MODE=warn
  [ "$HV_GUARD_LEVEL" = strict ] && HV_AGENT_GUARD_MODE=block
  HV_DIFF_BUDGET=${HV_DIFF_BUDGET:-800}
  HV_HAS_COMMANDS=''
  [ -z "$HV_LINT_CMD$HV_TYPECHECK_CMD$HV_TEST_CMD$HV_EVAL_CMD" ] || HV_HAS_COMMANDS=1
  export HV_HARNESS_VERSION HV_MULTI_AGENT HV_GUARD_STRICT HV_AGENT_GUARD_MODE HV_DIFF_BUDGET HV_HAS_COMMANDS

  # Profile flags. ENGINEERING: profiles whose work ships through PRs and CI.
  # SOLO: one person, no review flow (pushing to the default branch is fine).
  HV_PROFILE=${HV_PROFILE:-software}
  for m in $ALL_PROFILES; do
    up=$(printf '%s' "$m" | tr 'a-z' 'A-Z')
    if [ "$HV_PROFILE" = "$m" ]; then printf -v "HV_PROFILE_$up" '1'; else printf -v "HV_PROFILE_$up" ''; fi
    export "HV_PROFILE_$up"
  done
  HV_PROFILE_TITLE=$(profile_field "$HV_PROFILE" TITLE)
  HV_PROFILE_ENGINEERING='' HV_PROFILE_SOLO='' HV_PROTECT_RAW_DATA=''
  case $HV_PROFILE in software | ml | agentic) HV_PROFILE_ENGINEERING=1 ;; esac
  case $HV_PROFILE in study) HV_PROFILE_SOLO=1 ;; esac
  case $HV_PROFILE in ml | research) HV_PROTECT_RAW_DATA=1 ;; esac
  HV_NOTEBOOK_CHECK=$HV_PROTECT_RAW_DATA
  HV_HOW_WE_WORK=''
  case $HV_PROFILE in software | ml | agentic | research) HV_HOW_WE_WORK=1 ;; esac
  HV_PROFILE_RULES=''
  case $HV_PROFILE in ml | agentic | study | research) HV_PROFILE_RULES=1 ;; esac
  export HV_HOW_WE_WORK HV_PROFILE_RULES
  export HV_PROFILE HV_PROFILE_TITLE HV_PROFILE_ENGINEERING HV_PROFILE_SOLO HV_PROTECT_RAW_DATA HV_NOTEBOOK_CHECK

  for m in $ALL_MODULES; do
    up=$(printf '%s' "$m" | tr 'a-z-' 'A-Z_')
    if list_has "$HV_MODULES" "$m"; then printf -v "HV_MOD_$up" '1'; else printf -v "HV_MOD_$up" ''; fi
    export "HV_MOD_$up"
  done
  for m in node python go rust generic; do
    up=$(printf '%s' "$m" | tr 'a-z' 'A-Z')
    if [ "$HV_STACK" = "$m" ]; then printf -v "HV_STACK_$up" '1'; else printf -v "HV_STACK_$up" ''; fi
    export "HV_STACK_$up"
  done
  for m in npm pnpm yarn bun uv poetry pip; do
    up=$(printf '%s' "$m" | tr 'a-z' 'A-Z')
    if [ "$HV_PKG_MANAGER" = "$m" ]; then printf -v "HV_PM_$up" '1'; else printf -v "HV_PM_$up" ''; fi
    export "HV_PM_$up"
  done

  HV_DEPENDABOT_ECOSYSTEM='' HV_CODEQL_LANGUAGE='' HV_CODEQL_BUILD_MODE=none
  case $HV_STACK in
    node) HV_DEPENDABOT_ECOSYSTEM=npm HV_CODEQL_LANGUAGE=javascript-typescript ;;
    python)
      HV_CODEQL_LANGUAGE=python
      if [ "$HV_PKG_MANAGER" = uv ]; then HV_DEPENDABOT_ECOSYSTEM=uv; else HV_DEPENDABOT_ECOSYSTEM=pip; fi
      ;;
    go) HV_DEPENDABOT_ECOSYSTEM=gomod HV_CODEQL_LANGUAGE=go HV_CODEQL_BUILD_MODE=autobuild ;;
    rust) HV_DEPENDABOT_ECOSYSTEM=cargo HV_CODEQL_LANGUAGE=rust ;;
  esac
  export HV_DEPENDABOT_ECOSYSTEM HV_CODEQL_LANGUAGE HV_CODEQL_BUILD_MODE
}
