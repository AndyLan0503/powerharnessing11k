# shellcheck shell=bash
# Shared helpers. Must stay bash 3.2 compatible (stock macOS): no associative
# arrays, no ${var,,}, no mapfile, no `declare -n`.

HARNESS_NAME=powerharnessing11k

harness_die() {
  printf '%s\n' "$HARNESS_NAME: $*" >&2
  exit 1
}

# set_var NAME VALUE: assign to a variable whose name is computed. Use this
# instead of `printf -v`: bash 3.2 leaves NAME unset when VALUE is empty.
set_var() {
  eval "$1=\$2"
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

harness_tmpdir() {
  if [ -z "${HARNESS_TMP:-}" ]; then
    HARNESS_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t harness)
    # shellcheck disable=SC2064
    trap "rm -rf '$HARNESS_TMP'" EXIT
  fi
  printf '%s' "$HARNESS_TMP"
}
