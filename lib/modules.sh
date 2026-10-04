# shellcheck shell=bash
# Module registry. A module is modules/<name>/module.sh defining MODULE_DESC
# and module_apply(), which calls emit / settings_* (see lib/apply.sh and
# lib/settings.sh). Order matters only for readability of the summary.

ALL_MODULES="core guardrails quality audit skills collab ci security agent-guard review telemetry"

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

preset_load() { # name -> sets HV_GUARD_LEVEL HV_MODULES
  local file=$HARNESS_ROOT/presets/$1.preset line key val
  [ -f "$file" ] || harness_die "unknown preset '$1' (minimal, standard, strict)"
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in '' | '#'*) continue ;; esac
    key=${line%%=*}
    val=${line#*=}
    case $key in
      GUARD_LEVEL) HV_GUARD_LEVEL=$val ;;
      MODULES) HV_MODULES=$val ;;
    esac
  done <"$file"
  export HV_GUARD_LEVEL HV_MODULES
}

preset_desc() {
  sed -n 's/^# \{0,1\}//p' "$HARNESS_ROOT/presets/$1.preset" | tr '\n' ' '
}

# Flags derived from answers, used by templates ({{#if MOD_CI}} etc.).
derive_vars() {
  local m up
  HV_HARNESS_VERSION=$HARNESS_VERSION
  HV_HARNESS_URL=$(harness_url)
  export HV_HARNESS_URL
  HV_MULTI_AGENT=''
  [ "$HV_AGENT_TOOLS" = multi ] && HV_MULTI_AGENT=1
  HV_GUARD_STRICT=''
  [ "$HV_GUARD_LEVEL" = strict ] && HV_GUARD_STRICT=1
  HV_AGENT_GUARD_MODE=warn
  [ "$HV_GUARD_LEVEL" = strict ] && HV_AGENT_GUARD_MODE=block
  HV_DIFF_BUDGET=${HV_DIFF_BUDGET:-800}
  HV_HAS_COMMANDS=''
  [ -z "$HV_LINT_CMD$HV_TYPECHECK_CMD$HV_TEST_CMD" ] || HV_HAS_COMMANDS=1
  export HV_HARNESS_VERSION HV_MULTI_AGENT HV_GUARD_STRICT HV_AGENT_GUARD_MODE HV_DIFF_BUDGET HV_HAS_COMMANDS

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
