# shellcheck shell=bash
# Writing files into the target repo. Four modes, chosen per file by modules:
#
#   file   Whole file owned by harness. Tracked in .harness/manifest by sha256.
#          Updated only while it still matches what harness last wrote; once a
#          human edits it, harness writes <path>.harness-new beside it instead.
#   exec   Same as file, plus chmod +x (hook scripts).
#   block  Harness owns only the region between ">>> harness:managed" and
#          "<<< harness:managed" marker lines; everything else is yours.
#   seed   Written once if missing, never touched again.

BLOCK_START='>>> harness:managed'
BLOCK_END='<<< harness:managed'

apply_reset() {
  : >"$HARNESS_TMP/status"
  : >"$HARNESS_TMP/manifest.new"
}

_status() { # kind path [note]
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >>"$HARNESS_TMP/status"
}

_write() { # tmp dest
  [ -n "${DRY_RUN:-}" ] && return 0
  mkdir -p "$(dirname "$TARGET/$2")"
  cp "$1" "$TARGET/$2"
}

# emit MODE SRC DEST — render SRC (relative to the module dir) to DEST
# (relative to the target repo).
emit() {
  local mode=$1 src=$MODULE_DIR/$2 dest=$3 out
  [ -f "$src" ] || harness_die "module $MODULE_NAME: missing template $2"
  HARNESS_SEQ=$((${HARNESS_SEQ:-0} + 1))
  out=$HARNESS_TMP/render.$HARNESS_SEQ
  render_template "$src" "$out" || harness_die "module $MODULE_NAME: failed to render $2"
  apply_rendered "$mode" "$out" "$dest"
}

apply_rendered() { # mode tmp dest
  local mode=$1 tmp=$2 dest=$3 path=$TARGET/$3
  case $mode in
    file | exec) _apply_file "$mode" "$tmp" "$dest" ;;
    block) _apply_block "$tmp" "$dest" ;;
    seed)
      if [ -e "$path" ]; then
        _status kept "$dest"
      else
        _write "$tmp" "$dest"
        _status created "$dest"
      fi
      ;;
    *) harness_die "unknown emit mode: $mode" ;;
  esac
}

_apply_file() {
  local mode=$1 tmp=$2 dest=$3 path=$TARGET/$3 new_sha cur_sha rec_sha
  new_sha=$(harness_sha "$tmp")
  if [ ! -e "$path" ]; then
    _write "$tmp" "$dest"
    _status created "$dest"
    manifest_record "$dest" "$new_sha"
  else
    cur_sha=$(harness_sha "$path")
    rec_sha=$(manifest_get "$dest")
    if [ "$cur_sha" = "$new_sha" ]; then
      _status unchanged "$dest"
      manifest_record "$dest" "$new_sha"
    elif [ -n "${FORCE:-}" ] || { [ -n "$rec_sha" ] && [ "$cur_sha" = "$rec_sha" ]; }; then
      _write "$tmp" "$dest"
      _status updated "$dest"
      manifest_record "$dest" "$new_sha"
    else
      # Locally modified (or pre-existing and never managed): keep theirs.
      _write "$tmp" "$dest.harness-new"
      _status conflict "$dest" "kept yours; proposed version in $dest.harness-new"
      [ -z "$rec_sha" ] || manifest_record "$dest" "$rec_sha"
      return 0
    fi
  fi
  if [ "$mode" = exec ] && [ -z "${DRY_RUN:-}" ]; then chmod +x "$path"; fi
  if [ -z "${DRY_RUN:-}" ]; then rm -f "$path.harness-new"; fi
}

_apply_block() {
  local tmp=$1 dest=$2 path=$TARGET/$2 block merged
  grep -q "$BLOCK_START" "$tmp" || harness_die "template for $dest has no managed block markers"
  if [ ! -e "$path" ]; then
    _write "$tmp" "$dest"
    _status created "$dest"
    return
  fi
  block=$tmp.block
  merged=$tmp.merged
  awk -v s="$BLOCK_START" -v e="$BLOCK_END" \
    'index($0, s) { on = 1 } on { print } index($0, e) { on = 0 }' "$tmp" >"$block"
  if grep -q "$BLOCK_START" "$path"; then
    awk -v s="$BLOCK_START" -v e="$BLOCK_END" -v blk="$block" '
      index($0, s) && !done { while ((getline l < blk) > 0) print l; skip = 1; next }
      skip && index($0, e) { skip = 0; done = 1; next }
      !skip { print }' "$path" >"$merged"
  else
    { cat "$path"; [ -z "$(tail -c 1 "$path")" ] || echo; echo; cat "$block"; } >"$merged"
  fi
  if cmp -s "$merged" "$path"; then
    _status unchanged "$dest"
  else
    _write "$merged" "$dest"
    _status updated "$dest" "managed block only"
  fi
}

apply_summary() { # -> prints summary, returns number of conflicts (capped)
  local kind path note conflicts=0 sym color
  while IFS="$(printf '\t')" read -r kind path note; do
    case $kind in
      created) sym='+' color=$C_OK ;;
      updated) sym='~' color=$C_ACCENT ;;
      unchanged) sym='=' color=$C_DIM ;;
      kept) sym='·' color=$C_DIM ;;
      conflict) sym='!' color=$C_WARN conflicts=$((conflicts + 1)) ;;
    esac
    printf '  %s%s %-9s%s %s' "$color" "$sym" "$kind" "$C_RESET" "$path"
    [ -z "$note" ] || printf '  %s' "${C_DIM}($note)${C_RESET}"
    printf '\n'
  done <"$HARNESS_TMP/status"
  APPLY_CONFLICTS=$conflicts
}
