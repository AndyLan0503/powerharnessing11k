# shellcheck shell=bash
# Writing files into the target repo. harness runs once per repo: it creates
# what is missing and never manages files afterwards. Modes, chosen by modules:
#
#   file    Create if missing. If the file exists it is left alone (reported as
#           skipped) unless --force is given.
#   exec    Same as file, plus chmod +x (hook and helper scripts).
#   append  Line-based files such as .gitignore: append the template's lines
#           that are not already present. Existing lines are never touched.
#
# "seed" is accepted as a synonym for "file".

apply_reset() {
  : >"$HARNESS_TMP/status"
  APPLY_APPENDED=''
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
    file | seed | exec)
      if [ ! -e "$path" ]; then
        _write "$tmp" "$dest"
        _status created "$dest"
      elif [ -n "${FORCE:-}" ]; then
        if cmp -s "$tmp" "$path"; then
          _status unchanged "$dest"
        else
          _write "$tmp" "$dest"
          _status overwritten "$dest"
        fi
      else
        _status skipped "$dest" "already exists; left as is"
        return 0
      fi
      if [ "$mode" = exec ] && [ -z "${DRY_RUN:-}" ]; then chmod +x "$path"; fi
      ;;
    append) _apply_append "$tmp" "$dest" ;;
    *) harness_die "unknown emit mode: $mode" ;;
  esac
}

_apply_append() { # tmp dest
  local tmp=$1 dest=$2 path=$TARGET/$2 missing=$HARNESS_TMP/append.missing
  if [ ! -e "$path" ]; then
    _write "$tmp" "$dest"
    _status created "$dest"
    return
  fi
  # Template lines (comments and blanks excluded) not already in the file.
  awk 'NR == FNR { have[$0] = 1; next } /^[[:space:]]*(#|$)/ { next } !($0 in have)' \
    "$path" "$tmp" >"$missing"
  if [ ! -s "$missing" ]; then
    _status unchanged "$dest"
    return
  fi
  if [ -z "${DRY_RUN:-}" ]; then
    local last
    last=$(tail -c 1 "$path")
    {
      [ -z "$last" ] || echo
      # One header per file per run, however many modules append to it.
      case " $APPLY_APPENDED " in
        *" $dest "*) ;;
        *) echo; echo "# Added by the agent harness bootstrap" ;;
      esac
      cat "$missing"
    } >>"$path"
    APPLY_APPENDED="$APPLY_APPENDED $dest"
  fi
  _status appended "$dest" "$(wc -l <"$missing" | tr -d ' ') line(s)"
}

# Per-file list (--verbose). Sets APPLY_SKIPPED.
apply_summary_full() {
  local kind path note sym color
  while IFS="$(printf '\t')" read -r kind path note; do
    case $kind in
      created | appended) sym='+' color=$C_OK ;;
      overwritten) sym='~' color=$C_WARN ;;
      unchanged | skipped) sym='·' color=$C_DIM ;;
      *) sym='?' color='' ;;
    esac
    printf '  %s%s %-11s%s %s' "$color" "$sym" "$kind" "$C_RESET" "$path"
    [ -z "$note" ] || printf '  %s' "${C_DIM}($note)${C_RESET}"
    printf '\n'
  done <"$HARNESS_TMP/status"
  APPLY_SKIPPED=$(grep -c '^skipped' "$HARNESS_TMP/status" || true)
}

# Grouped summary: per class (written, kept), root files on one line and one
# line per top-level directory with its contents and counts. Overwritten
# files are listed individually, since those are the ones to look at.
# Sets APPLY_SKIPPED.
apply_summary() {
  awk -F '\t' -v ok="$C_OK" -v warn="$C_WARN" -v dim="$C_DIM" -v bold="$C_BOLD" -v reset="$C_RESET" '
    function add(list, item) { return list == "" ? item : list ", " item }
    function record(cls, path, label,    n, parts, top, key, sub_) {
      total[cls]++
      n = split(path, parts, "/")
      if (n == 1) {
        if (!((cls, path) in rootseen)) { rootseen[cls, path] = 1; roots[cls] = add(roots[cls], path label) }
        return
      }
      top = parts[1] "/"
      if (!((cls, top) in tops)) { tops[cls, top] = 1; order[cls, ++ntop[cls]] = top }
      sub_ = (n == 2) ? parts[2] : parts[2] "/"
      key = cls SUBSEP top SUBSEP sub_
      if (!(key in subcount)) subs[cls, top] = subs[cls, top] SUBSEP sub_
      subcount[key]++
    }
    function show(cls, sym, color,    i, j, m, list, top, detail, c) {
      if (roots[cls] != "") printf "  %s%s%s %-14s %s\n", color, sym, reset, "./", roots[cls]
      for (i = 1; i <= ntop[cls]; i++) {
        top = order[cls, i]
        m = split(substr(subs[cls, top], 2), list, SUBSEP)
        detail = ""
        for (j = 1; j <= m; j++) {
          c = subcount[cls SUBSEP top SUBSEP list[j]]
          detail = add(detail, list[j] ((list[j] ~ /\/$/ && c > 1) ? " " c : ""))
        }
        printf "  %s%s%s %-14s %s%s%s\n", color, sym, reset, top, dim, detail, reset
      }
    }
    $1 == "created" { record("w", $2, ""); next }
    $1 == "appended" { record("w", $2, " (appended)"); next }
    $1 == "overwritten" { over = over "  " warn "~" reset " " $2 "\n"; nover++; next }
    $1 == "skipped" { record("k", $2, ""); next }
    $1 == "unchanged" { nsame++; next }
    END {
      printf "  %s%d file(s) written%s", bold, total["w"] + 0, reset
      if (nover) printf ", %d overwritten", nover
      if (total["k"]) printf ", %d already there and kept", total["k"]
      if (nsame) printf ", %d unchanged", nsame
      printf "\n\n"
      show("w", "+", ok)
      if (nover) printf "%s", over
      if (total["k"]) { if (total["w"] || nover) printf "\n"; show("k", "·", dim) }
    }' "$HARNESS_TMP/status"
  APPLY_SKIPPED=$(grep -c '^skipped' "$HARNESS_TMP/status" || true)
}

# Files written in this run that still contain TODO(team), one per line.
apply_todo_files() {
  local kind path
  while IFS="$(printf '\t')" read -r kind path _; do
    case $kind in created | appended | overwritten) ;; *) continue ;; esac
    [ -f "$TARGET/$path" ] || continue
    if grep -q 'TODO(team)' "$TARGET/$path" 2>/dev/null; then printf '%s\n' "$path"; fi
  done <"$HARNESS_TMP/status" | awk '!seen[$0]++'
}
