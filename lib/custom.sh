# shellcheck shell=bash
# Project-specific stubs. harness doesn't know your domain (your solver, your
# data sources, your review checklist), so instead of guessing it creates
# blank, correctly placed files that tell the team what to write:
#
#   HV_SKILLS  "name name"            -> .claude/skills/<name>/SKILL.md
#   HV_ROLES   "name name"            -> .claude/agents/<name>.md
#   HV_RULES   "name=glob[,glob] ..." -> .claude/rules/<name>.md (path-scoped)
#   HV_DIRS    "dir dir/sub"          -> <dir>/README.md
#
# Templates live in modules/custom/. Every stub contains "TODO(team)".

_name_ok() { printf '%s' "$1" | grep -Eq '^[a-z0-9][a-z0-9-]{0,40}$'; }
_glob_ok() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._/*?-]+$'; }
_dir_ok() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_][A-Za-z0-9._-]*(/[A-Za-z0-9_][A-Za-z0-9._-]*)*$' &&
    ! printf '%s' "$1" | grep -q '\.\.'
}

# Globs like src/** must reach the rule file as written, so pathname expansion
# is off (set -f) while these functions word-split the lists.
custom_validate() {
  local item name globs g
  set -f
  for item in ${HV_SKILLS:-} ${HV_ROLES:-}; do
    _name_ok "$item" || harness_die "invalid skill/role name '$item' (use lowercase letters, digits, and hyphens)"
  done
  for item in ${HV_RULES:-}; do
    case $item in *=*) ;; *) harness_die "invalid rule '$item' (expected name=glob[,glob])" ;; esac
    name=${item%%=*}
    globs=${item#*=}
    _name_ok "$name" || harness_die "invalid rule name '$name' (use lowercase letters, digits, and hyphens)"
    [ -n "$globs" ] || harness_die "rule '$name' needs at least one glob"
    for g in ${globs//,/ }; do
      _glob_ok "$g" || harness_die "invalid glob '$g' in rule '$name' (letters, digits, . _ / * ? - only)"
    done
  done
  for item in ${HV_DIRS:-}; do
    _dir_ok "$item" || harness_die "invalid directory '$item' (relative path, no '..')"
  done
  set +f
}

custom_has_stubs() { [ -n "${HV_SKILLS:-}${HV_ROLES:-}${HV_RULES:-}${HV_DIRS:-}" ]; }

custom_apply() {
  local item name globs g paths
  MODULE_NAME=custom
  MODULE_DIR=$HARNESS_ROOT/modules/custom
  export MODULE_DIR
  for item in ${HV_SKILLS:-}; do
    HV_ITEM_NAME=$item
    export HV_ITEM_NAME
    emit file skill.md ".claude/skills/$item/SKILL.md"
  done
  for item in ${HV_ROLES:-}; do
    HV_ITEM_NAME=$item
    export HV_ITEM_NAME
    emit file role.md ".claude/agents/$item.md"
  done
  set -f
  for item in ${HV_RULES:-}; do
    name=${item%%=*}
    globs=${item#*=}
    paths=''
    for g in ${globs//,/ }; do paths="${paths:+$paths, }$(printf '"%s"' "$g")"; done
    HV_ITEM_NAME=$name HV_ITEM_PATHS=$paths
    export HV_ITEM_NAME HV_ITEM_PATHS
    emit file rule.md ".claude/rules/$name.md"
  done
  set +f
  for item in ${HV_DIRS:-}; do
    HV_ITEM_NAME=$item
    export HV_ITEM_NAME
    emit file dir-readme.md "$item/README.md"
  done
}
