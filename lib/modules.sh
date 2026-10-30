# shellcheck shell=bash
# Module registry. A module is modules/<name>/module.sh defining MODULE_DESC
# and module_apply(), which calls emit / settings_* (see lib/apply.sh and
# lib/settings.sh). Order matters only for readability of the summary.

ALL_MODULES="core guardrails quality audit devtools skills ml agentic study research artifacts mcp collab ci security diff-guard review telemetry"
ALL_PROFILES="software ml agentic study research"
ALL_TIERS="minimal recommended strict"
# Modules that write GitHub Actions workflows. Opt-in (HV_ACTIONS, --actions):
# a tier's list names what it gets with Actions, and profile_load leaves these
# out unless they were asked for.
ACTIONS_MODULES="ci security diff-guard review"

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

# tier_modules PROFILE FIELD [actions]: a tier's modules (FIELD is MINIMAL,
# RECOMMENDED, or STRICT) without its GitHub Actions ones; with "actions",
# only those.
tier_modules() {
  local m out=''
  for m in $(profile_field "$1" "$2"); do
    if list_has "$ACTIONS_MODULES" "$m"; then
      [ -n "${3:-}" ] || continue
    else
      [ -z "${3:-}" ] || continue
    fi
    out="${out:+$out }$m"
  done
  printf '%s' "$out"
}

profile_load() { # profile tier -> sets HV_PROFILE HV_TIER HV_MODULES HV_GUARD_LEVEL HV_TIER_ACTIONS
  local tier field
  tier=$(tier_normalize "$2")
  HV_PROFILE=$1 HV_TIER=$tier
  case $tier in
    minimal) field=MINIMAL HV_GUARD_LEVEL=relaxed ;;
    recommended) field=RECOMMENDED HV_GUARD_LEVEL=$(profile_field "$1" GUARD_LEVEL) ;;
    strict) field=STRICT HV_GUARD_LEVEL=$(profile_field "$1" STRICT_GUARD) ;;
  esac
  HV_MODULES=$(tier_modules "$1" "$field")
  # The tier's workflows, added only when asked for; a tier that names none
  # gets plain CI.
  HV_TIER_ACTIONS=$(tier_modules "$1" "$field" actions)
  [ -n "$HV_TIER_ACTIONS" ] || HV_TIER_ACTIONS=ci
  [ -z "${HV_ACTIONS:-}" ] || HV_MODULES=$(modules_normalize "$HV_MODULES $HV_TIER_ACTIONS")
  export HV_PROFILE HV_TIER HV_MODULES HV_GUARD_LEVEL HV_TIER_ACTIONS
}

# set_flags PREFIX SELECTED NAME...: exports PREFIX_NAME (upper case, "-" as
# "_") for each NAME: 1 when NAME is in the space-separated SELECTED list,
# empty otherwise. One tr for all names: a subshell each adds up on Windows.
set_flags() {
  local prefix=$1 selected=$2 m up ups
  shift 2
  ups=$(printf '%s ' "$@" | tr 'a-z-' 'A-Z_')
  for m in "$@"; do
    up=${ups%% *}
    ups=${ups#* }
    if list_has "$selected" "$m"; then set_var "${prefix}_$up" 1; else set_var "${prefix}_$up" ''; fi
    export "${prefix}_$up"
  done
}

# Flags derived from answers, used by templates ({{#if MOD_CI}} etc.).
derive_vars() {
  local m up
  HV_HARNESS_VERSION=$HARNESS_VERSION
  HV_GUARD_RELAXED='' HV_GUARD_STANDARD='' HV_GUARD_STRICT=''
  case $HV_GUARD_LEVEL in
    relaxed) HV_GUARD_RELAXED=1 ;;
    standard) HV_GUARD_STANDARD=1 ;;
    strict) HV_GUARD_STRICT=1 ;;
  esac
  export HV_GUARD_RELAXED HV_GUARD_STANDARD
  HV_DIFF_GUARD_MODE=warn
  [ "$HV_GUARD_LEVEL" = strict ] && HV_DIFF_GUARD_MODE=block
  HV_DIFF_BUDGET=${HV_DIFF_BUDGET:-800}
  HV_HAS_COMMANDS=''
  [ -z "$HV_LINT_CMD$HV_TYPECHECK_CMD$HV_TEST_CMD$HV_EVAL_CMD" ] || HV_HAS_COMMANDS=1
  export HV_HARNESS_VERSION HV_GUARD_STRICT HV_DIFF_GUARD_MODE HV_DIFF_BUDGET HV_HAS_COMMANDS

  # Profile flags. ENGINEERING: profiles whose work ships through PRs and CI.
  # SOLO: one person, no review flow (pushing to the default branch is fine).
  HV_PROFILE=${HV_PROFILE:-software}
  # shellcheck disable=SC2086 # word lists on purpose
  set_flags HV_PROFILE "$HV_PROFILE" $ALL_PROFILES
  HV_PROFILE_TITLE=$(profile_field "$HV_PROFILE" TITLE)
  HV_PROFILE_ENGINEERING='' HV_PROFILE_SOLO='' HV_PROTECT_RAW_DATA=''
  case $HV_PROFILE in software | ml | agentic) HV_PROFILE_ENGINEERING=1 ;; esac
  case $HV_PROFILE in study) HV_PROFILE_SOLO=1 ;; esac
  case $HV_PROFILE in ml | research) HV_NOTEBOOK_CHECK=1 ;; *) HV_NOTEBOOK_CHECK='' ;; esac
  # Raw data is protected wherever data is versioned (or the profile is data-centric).
  if [ -n "$HV_NOTEBOOK_CHECK" ] || list_has "$HV_MODULES" artifacts; then HV_PROTECT_RAW_DATA=1; fi
  HV_HOW_WE_WORK=''
  case $HV_PROFILE in software | ml | agentic | research) HV_HOW_WE_WORK=1 ;; esac
  export HV_HOW_WE_WORK

  # devtools: a Makefile unless the repo has one; a Python skeleton only in a
  # Python/uv repo that has no pyproject.toml yet. --force never changes this:
  # it refreshes harness files, never the project's own build or code.
  HV_USE_MAKE='' HV_SCAFFOLD_PYTHON=''
  if list_has "$HV_MODULES" devtools; then
    if [ ! -e "$TARGET/Makefile" ] && [ ! -e "$TARGET/makefile" ] && [ ! -e "$TARGET/GNUmakefile" ]; then
      HV_USE_MAKE=1
    elif [ -n "${FORCE:-}" ] && [ -f "$TARGET/Makefile" ] && grep -q '^check: lint typecheck test ## Everything a PR must pass' "$TARGET/Makefile"; then
      HV_USE_MAKE=1 # ours, from an earlier bootstrap
    fi
    if [ "$HV_STACK" = python ] && [ "$HV_PKG_MANAGER" = uv ] && [ ! -e "$TARGET/pyproject.toml" ]; then
      HV_SCAFFOLD_PYTHON=1
    fi
  fi
  # Commands as Makefile recipe lines: make expands $, so double it. A command
  # that calls make would have the generated Makefile call itself.
  local k v
  for k in INSTALL LINT TYPECHECK TEST FULL_TEST; do
    eval "v=\${HV_${k}_CMD:-}"
    if [ -n "$HV_USE_MAKE" ]; then
      case " $v" in
        *" make "* | *" make" | *'$(MAKE)'* | *'${MAKE}'*)
          harness_die "the $(printf '%s' "$k" | tr 'A-Z_' 'a-z-') command '$v' calls make, but harness writes the Makefile here. Give the underlying command instead." ;;
      esac
    fi
    set_var "HV_MK_${k}_CMD" "${v//\$/\$\$}"
    export "HV_MK_${k}_CMD"
  done
  HV_PY_DIST=$(printf '%s' "$HV_PROJECT_NAME" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//')
  HV_PY_PACKAGE=$(printf '%s' "$HV_PY_DIST" | tr '-' '_')
  case $HV_PY_PACKAGE in '' ) HV_PY_PACKAGE=app HV_PY_DIST=app ;; [0-9]*) HV_PY_PACKAGE="pkg_$HV_PY_PACKAGE" ;; esac
  export HV_USE_MAKE HV_SCAFFOLD_PYTHON HV_PY_DIST HV_PY_PACKAGE

  # Jobs the PR gate waits for.
  HV_GATE_NEEDS=''
  if list_has "$HV_MODULES" diff-guard; then HV_GATE_NEEDS=guard; fi
  if list_has "$HV_MODULES" review; then HV_GATE_NEEDS="${HV_GATE_NEEDS:+$HV_GATE_NEEDS, }review"; fi
  export HV_GATE_NEEDS
  export HV_PROFILE HV_PROFILE_TITLE HV_PROFILE_ENGINEERING HV_PROFILE_SOLO HV_PROTECT_RAW_DATA HV_NOTEBOOK_CHECK

  # shellcheck disable=SC2086
  set_flags HV_MOD "$HV_MODULES" $ALL_MODULES
  # The files that mean "the project exists" for this stack. Until one does,
  # lint, typecheck, and tests have nothing to run against: the stop check
  # and the CI steps skip instead of failing.
  case $HV_STACK in
    node) HV_STACK_MANIFESTS='package.json' ;;
    python) HV_STACK_MANIFESTS='pyproject.toml requirements.txt setup.py' ;;
    go) HV_STACK_MANIFESTS='go.mod' ;;
    rust) HV_STACK_MANIFESTS='Cargo.toml' ;;
    *) HV_STACK_MANIFESTS='' ;;
  esac
  HV_CI_HAS_PROJECT='' HV_PROJECT_MISSING=''
  if [ -n "$HV_STACK_MANIFESTS" ]; then
    # A GitHub Actions expression; the quotes are part of the text.
    HV_CI_HAS_PROJECT=$(printf "hashFiles('%s') != ''" "$(printf '%s' "$HV_STACK_MANIFESTS" | sed "s/ /', '/g")")
    HV_PROJECT_MISSING=1
    for m in $HV_STACK_MANIFESTS; do [ ! -e "$TARGET/$m" ] || HV_PROJECT_MISSING=''; done
    [ -z "$HV_SCAFFOLD_PYTHON" ] || HV_PROJECT_MISSING=''
  fi
  case $HV_PKG_MANAGER in
    pnpm) HV_NODE_LOCKFILE=pnpm-lock.yaml ;;
    yarn) HV_NODE_LOCKFILE=yarn.lock ;;
    *) HV_NODE_LOCKFILE=package-lock.json ;;
  esac
  export HV_STACK_MANIFESTS HV_CI_HAS_PROJECT HV_PROJECT_MISSING HV_NODE_LOCKFILE
  set_flags HV_STACK "$HV_STACK" node python go rust generic
  set_flags HV_PM "${HV_PKG_MANAGER:-}" npm pnpm yarn bun uv poetry pip

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
