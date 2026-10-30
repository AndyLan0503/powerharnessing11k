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
# emit_symlink creates a relative symlink under the same create-only rule.
#
# "seed" is accepted as a synonym for "file".

apply_reset() {
  : >"$HARNESS_TMP/status"
  : >"$HARNESS_TMP/local.patterns"
  APPLY_APPENDED=''
}

_status() { # kind path [note]
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >>"$HARNESS_TMP/status"
}

_write() { # tmp dest
  local dir=$TARGET/$2
  [ -n "${DRY_RUN:-}" ] && return 0
  dir=${dir%/*}
  [ -d "$dir" ] || mkdir -p "$dir"
  cp "$1" "$TARGET/$2"
}

# emit MODE SRC DEST — render SRC (relative to the module dir) to DEST
# (relative to the target repo).
emit() {
  local mode=$1 src=$MODULE_DIR/$2 dest=$3 out dir
  [ -f "$src" ] || harness_die "module $MODULE_NAME: missing template $2"
  # A new file is rendered straight into place: one process instead of two.
  case $mode in
    file | seed | exec)
      if [ -z "${DRY_RUN:-}" ] && [ ! -e "$TARGET/$dest" ] && [ ! -L "$TARGET/$dest" ]; then
        dir=$TARGET/$dest
        dir=${dir%/*}
        [ -d "$dir" ] || mkdir -p "$dir"
        HARNESS_WRITING=$TARGET/$dest
        render_template "$src" "$TARGET/$dest" || harness_die "module $MODULE_NAME: failed to render $2"
        HARNESS_WRITING=''
        [ "$mode" != exec ] || chmod +x "$TARGET/$dest"
        _status created "$dest"
        return 0
      fi
      ;;
  esac
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

# emit_symlink TARGET DEST: DEST (relative to the repo) becomes a symlink to
# TARGET (relative to DEST's directory). Create-only, like files: an existing
# file or directory is never replaced. With --force, a link that points
# somewhere else is repointed (a link holds no content of its own).
emit_symlink() {
  local link_to=$1 dest=$2 path=$TARGET/$2
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$link_to" ]; then
    _status unchanged "$dest"
  elif [ -L "$path" ] && [ -n "${FORCE:-}" ]; then
    if [ -z "${DRY_RUN:-}" ]; then
      rm "$path"
      _link "$link_to" "$dest"
    fi
    _status overwritten "$dest" "link to $link_to"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    _status skipped "$dest" "already exists; left as is"
  else
    if [ -z "${DRY_RUN:-}" ]; then
      mkdir -p "$(dirname "$path")"
      _link "$link_to" "$dest"
    fi
    _status created "$dest" "link to $link_to"
  fi
}

# On Windows, the ln of Git Bash, MSYS2, and Cygwin copies the target unless
# told to make a real link. These variables ask for one, and for an error
# instead of a copy when Windows does not allow it; elsewhere they are ignored.
LINK_ENV='MSYS=winsymlinks:nativestrict CYGWIN=winsymlinks:nativestrict'

# check_links: stop before anything is written if this machine cannot make
# symbolic links (Windows without Developer Mode), so a refusal never leaves
# a half-written setup behind.
check_links() {
  local probe=$HARNESS_TMP/link-probe err
  [ -z "${DRY_RUN:-}" ] || return 0
  rm -rf "$probe"
  mkdir -p "$probe/target"
  # shellcheck disable=SC2086 # LINK_ENV is several assignments on purpose
  if ! err=$(env $LINK_ENV ln -s target "$probe/link" 2>&1) || [ ! -L "$probe/link" ]; then
    rm -rf "$probe"
    harness_die "this machine cannot create symbolic links${err:+ ($err)}. On Windows, turn on Developer Mode in Settings, then run this again. Nothing was written."
  fi
  rm -rf "$probe"
}

# _link TARGET DEST. A repository whose git was set up without symlink support
# has its links checked out as plain files, and would commit this one as a
# plain file too. It gets core.symlinks=true, and its existing links are
# checked out again as real links, or the next commit would turn them into
# plain files for everyone.
_link() {
  local err p
  # shellcheck disable=SC2086 # LINK_ENV is several assignments on purpose
  err=$(env $LINK_ENV ln -s "$1" "$TARGET/$2" 2>&1) ||
    harness_die "could not create the symbolic link $2: $err"
  if [ "$(git -C "$TARGET" config --bool core.symlinks 2>/dev/null)" = false ]; then
    git -C "$TARGET" config core.symlinks true
    git -C "$TARGET" ls-files -s | awk -F '\t' '$1 ~ /^120000 / { print $2 }' | while IFS= read -r p; do
      [ -L "$TARGET/$p" ] || git -C "$TARGET" checkout -- "$p"
    done
  fi
}

_apply_append() { # tmp dest
  local tmp=$1 dest=$2 path=$TARGET/$2 missing=$HARNESS_TMP/append.missing
  # --local-only: the repository's own .gitignore is not touched; the
  # patterns go to this machine's .git/info/exclude with everything else.
  if [ -n "${LOCAL_ONLY:-}" ] && [ "$dest" = .gitignore ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$tmp" >>"$HARNESS_TMP/local.patterns" || true
    return 0
  fi
  # Likewise, attributes go to this machine's .git/info/attributes.
  if [ -n "${LOCAL_ONLY:-}" ] && [ "$dest" = .gitattributes ]; then
    _apply_local_attributes "$tmp"
    return 0
  fi
  if [ ! -e "$path" ]; then
    _write "$tmp" "$dest"
    _status created "$dest"
    return
  fi
  # Template lines (comments and blanks excluded) not already in the file.
  awk 'FILENAME == ARGV[1] { have[$0] = 1; next } /^[[:space:]]*(#|$)/ { next } !($0 in have)' \
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

_apply_local_attributes() { # tmp
  local file
  file=$(git -C "$TARGET" rev-parse --git-path info/attributes 2>/dev/null) || harness_die "--local-only needs a git repository"
  case $file in /* | [A-Za-z]:*) ;; *) file=$TARGET/$file ;; esac
  [ -z "${DRY_RUN:-}" ] || return 0
  mkdir -p "$(dirname "$file")"
  touch "$file"
  awk 'FILENAME == ARGV[1] { have[$0] = 1; next } /^[[:space:]]*(#|$)/ { next } !($0 in have)' \
    "$file" "$1" >"$HARNESS_TMP/attributes.missing"
  cat "$HARNESS_TMP/attributes.missing" >>"$file"
}

# Per-file list (--verbose). Sets APPLY_SKIPPED.
apply_summary_full() {
  local kind path note sym color
  while IFS=$'\t' read -r kind path note; do
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

# Files written in this run that still contain TODO(team), one per line,
# AGENTS.md first. A marker inside `inline code` is text about the notes (as
# in the onboard skill), not a note to fill in. One awk reads every file.
apply_todo_files() {
  local kind path list=$HARNESS_TMP/todo.files
  : >"$list"
  while IFS=$'\t' read -r kind path _; do
    case $kind in created | appended | overwritten) ;; *) continue ;; esac
    [ -f "$TARGET/$path" ] && printf '%s\n' "$path" >>"$list"
  done <"$HARNESS_TMP/status"
  [ -s "$list" ] || return 0
  TODO_ROOT=$TARGET awk '
    !($0 in seen) { seen[$0] = 1; order[++n] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        f = order[i]; hit = 0
        while ((getline l < (ENVIRON["TODO_ROOT"] "/" f)) > 0) {
          gsub(/`[^`]*`/, "", l)
          if (index(l, "TODO(team)")) { hit = 1; break }
        }
        close(ENVIRON["TODO_ROOT"] "/" f)
        if (!hit) continue
        if (f == "AGENTS.md") first = f; else rest[++m] = f
      }
      if (first != "") print first
      for (i = 1; i <= m; i++) print rest[i]
    }' "$list"
}

# --local-only: keep everything this run wrote out of git on this machine,
# by listing it in .git/info/exclude (never committed, never shared). Files
# that were already there and kept are the user's and are not listed; files
# git already tracks cannot be ignored and are reported. The entries live in
# one marked block, so a re-run merges into it and removing it undoes it.
# Sets LOCAL_EXCLUDE_FILE, LOCAL_EXCLUDED (count), and LOCAL_TRACKED (paths).
LOCAL_BLOCK_BEGIN='# >>> agent setup files, kept out of git on this machine (remove this block to track them)'
LOCAL_BLOCK_END='# <<< agent setup files'
LOCAL_BLOCK_FILES='# files written by the bootstrap:'

apply_local_exclude() {
  local file entries=$HARNESS_TMP/local.entries patterns=$HARNESS_TMP/local.pats kind path _ old
  LOCAL_EXCLUDED=0 LOCAL_TRACKED=''
  file=$(git -C "$TARGET" rev-parse --git-path info/exclude 2>/dev/null) || harness_die "--local-only needs a git repository"
  case $file in /* | [A-Za-z]:*) ;; *) file=$TARGET/$file ;; esac
  LOCAL_EXCLUDE_FILE=$file
  : >"$entries"
  while IFS=$'\t' read -r kind path _; do
    case $kind in created | overwritten | unchanged) ;; *) continue ;; esac
    if git -C "$TARGET" ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      LOCAL_TRACKED="$LOCAL_TRACKED $path"
      continue
    fi
    # Anchored to the repository root; glob characters escaped.
    printf '/%s\n' "$path" | sed 's/[][*?\\]/\\&/g' >>"$entries"
  done <"$HARNESS_TMP/status"
  cp "$HARNESS_TMP/local.patterns" "$patterns"
  LOCAL_EXCLUDED=$(grep -c '^/' "$entries" || true)
  [ -z "${DRY_RUN:-}" ] || return 0

  old=$HARNESS_TMP/local.old
  : >"$old"
  [ -f "$file" ] && cp "$file" "$old"
  mkdir -p "$(dirname "$file")"
  # The block has two sections: the patterns a .gitignore would have had,
  # then one line per written file. The files come last because in an ignore
  # file a later line wins: a pattern such as "!/data/**/README.md" must not
  # un-ignore a file listed here. A re-run merges into each section; the
  # block stays where it is, and a begin marker without an end marker after
  # it is left alone as an ordinary line (a fresh block is appended).
  awk -v b="$LOCAL_BLOCK_BEGIN" -v e="$LOCAL_BLOCK_END" -v sep="$LOCAL_BLOCK_FILES" \
    -v newpats="$patterns" -v newfiles="$entries" '
    { line[++n] = $0 }
    END {
      start = 0; stop = 0
      for (i = 1; i <= n; i++) if (line[i] == b) { for (j = i + 1; j <= n; j++) if (line[j] == e) { start = i; stop = j; break } if (start) break }
      np = 0; nf = 0; section = "p"
      for (i = start + 1; start && i < stop; i++) {
        if (line[i] == sep) { section = "f"; continue }
        if (line[i] == "") continue
        if (section == "p") pats[++np] = line[i]; else files[++nf] = line[i]
      }
      while ((getline l < newpats) > 0) pats[++np] = l
      while ((getline l < newfiles) > 0) files[++nf] = l
      for (i = 1; i <= n; i++) {
        if (start && i == start) { emit(); i = stop; continue }
        print line[i]
      }
      if (!start) emit()
    }
    function emit(   i) {
      print b
      for (i = 1; i <= np; i++) if (pats[i] != "" && !seen[pats[i]]++) print pats[i]
      print sep
      for (i = 1; i <= nf; i++) if (files[i] != "" && !seen[files[i]]++) print files[i]
      print e
    }' "$old" >"$file"
}

# 0 when an earlier --local-only run left its block in this repository's
# exclude file (its files are still hidden from git).
local_block_present() {
  local file
  file=$(git -C "$TARGET" rev-parse --git-path info/exclude 2>/dev/null) || return 1
  case $file in /* | [A-Za-z]:*) ;; *) file=$TARGET/$file ;; esac
  [ -f "$file" ] && grep -qxF "$LOCAL_BLOCK_BEGIN" "$file" && grep -qxF "$LOCAL_BLOCK_END" "$file"
}
