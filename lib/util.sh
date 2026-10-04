# shellcheck shell=bash
# Shared helpers. Must stay bash 3.2 compatible (stock macOS): no associative
# arrays, no ${var,,}, no mapfile, no `declare -n`.

harness_die() {
  printf '%s\n' "harness: $*" >&2
  exit 1
}

# sha256 of a file, portable across GNU coreutils and macOS.
harness_sha() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Escape a string for embedding inside a JSON string literal.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//	/\\t}
  printf '%s' "$s"
}

# Space-separated list membership: list_has "a b c" b
list_has() {
  case " $1 " in *" $2 "*) return 0 ;; esac
  return 1
}

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# Browsable https URL for a git remote, with any credentials removed:
#   git@host:org/repo.git           -> https://host/org/repo
#   https://user:tok@host/org/repo  -> https://host/org/repo
web_url() {
  local u=$1 scheme rest
  case $u in
    git@*:*)
      u=${u#git@}
      u="https://${u%%:*}/${u#*:}"
      ;;
    ssh://*)
      u=${u#ssh://}
      u="https://${u#*@}"
      ;;
    http://* | https://*) ;;
    *) return 1 ;;
  esac
  scheme=${u%%://*}
  rest=${u#*://}
  case ${rest%%/*} in *@*) rest=${rest#*@} ;; esac
  u="$scheme://$rest"
  u=${u%/}
  printf '%s' "${u%.git}"
}

# Where this copy of harness came from, so a company fork links to itself.
HARNESS_UPSTREAM_DEFAULT=https://github.com/reclan-ai/harness-workflow
harness_url() {
  local remote
  if remote=$(git -C "$HARNESS_ROOT" remote get-url origin 2>/dev/null) && web_url "$remote"; then
    return 0
  fi
  printf '%s' "$HARNESS_UPSTREAM_DEFAULT"
}

harness_tmpdir() {
  if [ -z "${HARNESS_TMP:-}" ]; then
    HARNESS_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t harness)
    # shellcheck disable=SC2064
    trap "rm -rf '$HARNESS_TMP'" EXIT
  fi
  printf '%s' "$HARNESS_TMP"
}
