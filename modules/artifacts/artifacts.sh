#!/usr/bin/env bash
# Local, tool-agnostic versioning for data and model artifacts.
#
# The files themselves stay out of git (data/, models/). artifacts.lock, which
# IS committed, records the content hash of every file, so a commit pins the
# exact data and models it was built and tested with. When remote storage
# arrives (DVC, object storage), the lock is the migration list.
#
# Usage: scripts/artifacts.sh <command> [args]
#   snapshot [-m NOTE] [DIR|FILE ...]  record hashes (default: data models)
#   verify   [PREFIX ...]              exit 1 if a recorded file is missing or changed
#   status   [DIR ...]                 changed, missing, and unrecorded files
#   list                               recorded artifacts
#   hash PATH                          short hash of a recorded file (for logs)
#
# Lock format (tab-separated): sha256  bytes  path  recorded_at  note
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
LOCK=${ARTIFACTS_LOCK:-artifacts.lock}
DEFAULT_ROOTS="data models"

die() { echo "artifacts: $*" >&2; exit 2; }
# Hash stdin, so unusual file names can't change the output format.
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum <"$1"; else shasum -a 256 <"$1"; fi | awk '{print $1}'; }
bytes() { wc -c <"$1" | tr -d ' '; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
header() {
  printf '%s\n' "# artifacts.lock: content hashes of local data and model files. Commit this"
  printf '%s\n' "# file; the files themselves stay out of git. Update: scripts/artifacts.sh snapshot"
  printf '%s\n' "# sha256	bytes	path	recorded_at	note"
}
entries() { [ -f "$LOCK" ] && grep -v '^#' "$LOCK" | grep -v '^[[:space:]]*$' || true; }
# A root as the lock spells paths: no leading ./, no trailing /.
norm() {
  local r=$1
  while :; do
    case $r in ./*) r=${r#./} ;; */) r=${r%/} ;; *) break ;; esac
  done
  case $r in '' | . | /* | .. | ../* | */.. | */../*) die "not a path inside the repo: $1" ;; esac
  printf '%s' "$r"
}
# Callers run this in $(...), so they must check its status: `|| exit 2`.
norm_all() {
  local r n out=''
  for r in "$@"; do
    n=$(norm "$r") || exit 2
    out="$out $n"
  done
  printf '%s' "$out"
}
# The lock entry for one path (P in the environment, so no escape processing).
entry_for() { entries | P=$1 awk -F '\t' '$3 == ENVIRON["P"]'; }
# Files under the given roots, excluding documentation placeholders.
files_under() {
  local r
  for r in "$@"; do
    [ -e "$r" ] || continue
    if [ -f "$r" ]; then printf '%s\n' "$r"; continue; fi
    find "$r" -type f ! -name README.md ! -name .gitkeep ! -name '.*' 2>/dev/null
  done | sed 's|^\./||' | LC_ALL=C sort -u
}
under() { # path roots... -> 0 if path is one of / inside the roots
  local p=$1 r
  shift
  for r in "$@"; do
    r=${r%/}
    case $p in "$r" | "$r"/*) return 0 ;; esac
  done
  return 1
}

cmd_snapshot() {
  local note='' roots='' f h b old tmp n_new=0 n_changed=0 n_removed=0
  while [ $# -gt 0 ]; do
    case $1 in
      -m) note=${2:?-m needs a note}; shift ;;
      *) roots="$roots $1" ;;
    esac
    shift
  done
  case $note in *'	'* | *'
'*) die "the note cannot contain tabs or newlines" ;; esac
  # shellcheck disable=SC2086
  if [ -n "$roots" ]; then roots=$(norm_all $roots) || exit 2; else roots=$DEFAULT_ROOTS; fi
  [ -s "$LOCK" ] || header >"$LOCK"
  tmp=$(mktemp)
  # Keep entries outside the snapshotted roots untouched.
  # shellcheck disable=SC2086
  entries | while IFS='	' read -r h b f _ _; do
    under "$f" $roots || printf '%s\n' "$f"
  done >"$tmp.keep"
  {
    header
    entries | awk -F '\t' 'FILENAME == ARGV[1] { keep[$0] = 1; next } ($3 in keep)' "$tmp.keep" -
    # shellcheck disable=SC2086
    files_under $roots | while IFS= read -r f; do
      case $f in *'	'*) die "path contains a tab: $f" ;; esac
      h=$(sha "$f")
      b=$(bytes "$f")
      old=$(entry_for "$f")
      if [ -n "$old" ] && [ "$(printf '%s' "$old" | cut -f1)" = "$h" ]; then
        printf '%s\n' "$old" # unchanged: keep its original date and note
      else
        printf '%s\t%s\t%s\t%s\t%s\n' "$h" "$b" "$f" "$(now)" "$note"
      fi
    done
  } >"$tmp"
  # Summarise against the previous lock.
  n_new=$(awk -F '\t' 'FILENAME == ARGV[1] { if ($0 !~ /^#/) old[$3] = $1; next } $0 !~ /^#/ && !($3 in old)' "${LOCK}" "$tmp" 2>/dev/null | wc -l | tr -d ' ') || n_new=0
  n_changed=$(awk -F '\t' 'FILENAME == ARGV[1] { if ($0 !~ /^#/) old[$3] = $1; next } $0 !~ /^#/ && ($3 in old) && old[$3] != $1' "${LOCK}" "$tmp" 2>/dev/null | wc -l | tr -d ' ') || n_changed=0
  n_removed=$(awk -F '\t' 'FILENAME == ARGV[1] { if ($0 !~ /^#/) now[$3] = 1; next } $0 !~ /^#/ && !($3 in now)' "$tmp" "${LOCK}" 2>/dev/null | wc -l | tr -d ' ') || n_removed=0
  mv "$tmp" "$LOCK"
  rm -f "$tmp.keep"
  echo "artifacts.lock: $n_new new, $n_changed changed, $n_removed removed ($(entries | wc -l | tr -d ' ') recorded)"
}

cmd_verify() {
  local h b f bad=0 n=0
  [ -f "$LOCK" ] || die "no $LOCK yet; run: scripts/artifacts.sh snapshot"
  local rs
  if [ $# -gt 0 ]; then
    rs=$(norm_all "$@") || exit 2
    # shellcheck disable=SC2086
    set -- $rs
  fi
  while IFS='	' read -r h b f _ _; do
    [ -n "$f" ] || continue
    if [ $# -gt 0 ] && ! under "$f" "$@"; then continue; fi
    n=$((n + 1))
    if [ ! -f "$f" ]; then
      echo "MISSING  $f"
      bad=$((bad + 1))
    elif [ "$(sha "$f")" != "$h" ]; then
      echo "CHANGED  $f"
      bad=$((bad + 1))
    fi
  done <<EOF
$(entries)
EOF
  if [ "$bad" -gt 0 ]; then
    echo "artifacts: $bad of $n recorded file(s) do not match $LOCK" >&2
    return 1
  fi
  echo "artifacts: $n recorded file(s) verified"
}

cmd_status() {
  local roots f
  # shellcheck disable=SC2086
  if [ $# -gt 0 ]; then roots=$(norm_all "$@") || exit 2; else roots=$DEFAULT_ROOTS; fi
  # shellcheck disable=SC2086
  if [ -f "$LOCK" ]; then cmd_verify $roots || true; fi
  # shellcheck disable=SC2086
  files_under $roots | while IFS= read -r f; do
    [ -n "$(entry_for "$f")" ] || echo "NEW      $f"
  done
}

cmd_list() { entries | awk -F '\t' '{ printf "%s  %10s  %s  %s\n", substr($1, 1, 12), $2, $4, $3 }'; }

cmd_hash() {
  [ $# -eq 1 ] || die "usage: scripts/artifacts.sh hash PATH"
  local e
  local p
  p=$(norm "$1") || exit 2
  e=$(entry_for "$p")
  [ -n "$e" ] || die "$1 is not recorded in $LOCK"
  printf '%s\n' "$e" | awk -F '\t' '{ print substr($1, 1, 12) }'
}

cmd=${1:-}
[ $# -eq 0 ] || shift
case $cmd in
  snapshot) cmd_snapshot "$@" ;;
  verify) cmd_verify "$@" ;;
  status) cmd_status "$@" ;;
  list) cmd_list ;;
  hash) cmd_hash "$@" ;;
  *) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; [ -z "$cmd" ] || exit 2 ;;
esac
