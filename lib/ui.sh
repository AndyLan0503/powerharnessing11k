# shellcheck shell=bash
# Terminal UI for the configuration wizard, in the spirit of `p10k configure`:
# one question per screen, a key marks the answer and Enter confirms it,
# (r)estart and (q)uit everywhere.

HARNESS_TTY=${HARNESS_TTY:-/dev/tty}

ui_init() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m' C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
    C_ACCENT=$'\033[38;5;39m' C_OK=$'\033[38;5;71m' C_WARN=$'\033[38;5;178m' C_ERR=$'\033[38;5;160m'
  else
    C_RESET='' C_BOLD='' C_DIM='' C_ACCENT='' C_OK='' C_WARN='' C_ERR=''
  fi
}

ui_clear() {
  if [ -t 1 ] && [ -z "${HARNESS_NO_CLEAR:-}" ]; then printf '\033[H\033[2J'; fi
}

ui_banner() {
  printf '%s' "${C_ACCENT}${C_BOLD}"
  cat <<'EOF'

           _   _   _
   _ __   / | / | | | __
  | '_ \  | | | | | |/ /
  | |_) | | | | | |   <
  | .__/  |_| |_| |_|\_\
  |_|
EOF
  printf '%s\n' "${C_RESET}"
  printf '  %s\n\n' "${C_BOLD}$HARNESS_NAME${C_RESET}  ${C_DIM}one-shot agentic harness configurator · v$(cat "$HARNESS_ROOT/VERSION")${C_RESET}"
}

ui_header() { # step total title
  ui_clear
  ui_banner
  printf '  %s%s%s  %s\n\n' "$C_DIM" "[$1/$2]" "$C_RESET" "${C_BOLD}$3${C_RESET}"
}

ui_note() { printf '  %s\n' "${C_DIM}$*${C_RESET}"; }
ui_info() { printf '  %s\n' "$*"; }
ui_ok() { printf '  %s %s\n' "${C_OK}✔${C_RESET}" "$*"; }
ui_warn() { printf '  %s %s\n' "${C_WARN}!${C_RESET}" "$*"; }
ui_err() { printf '  %s %s\n' "${C_ERR}✘${C_RESET}" "$*" >&2; }

ui_footer() {
  printf '\n  %s\n' "${C_DIM}(r)  Restart from the beginning.${C_RESET}"
  printf '  %s\n\n' "${C_DIM}(q)  Quit and do nothing.${C_RESET}"
}

# Read one key from the terminal. Sets UI_KEY.
ui_key() {
  UI_KEY=''
  IFS= read -r -s -n 1 UI_KEY <"$HARNESS_TTY" || UI_KEY=q
}

# Read a line from the terminal with a default. Sets UI_LINE.
ui_line() { # prompt default
  local line
  printf '  %s %s' "${C_BOLD}$1${C_RESET}" "${C_DIM}[$2]${C_RESET} "
  IFS= read -r line <"$HARNESS_TTY" || line=''
  [ -n "$line" ] || line=$2
  UI_LINE=$line
}

# ui_choose "Title" step total "opt1|desc1" "opt2|desc2" ...
# Shows numbered options. A number key marks that option and echoes it after
# the prompt; Enter confirms the marked one. Sets UI_CHOICE to its 1-based index.
# Returns 10 on restart, exits on quit.
ui_choose() {
  local title=$1 step=$2 total=$3
  shift 3
  local n=0 opt label desc sel=''
  while :; do
    ui_header "$step" "$total" "$title"
    n=0
    for opt in "$@"; do
      n=$((n + 1))
      label=${opt%%|*}
      desc=${opt#*|}
      printf '%s%s  %s\n' "$(_ui_marker "$n" "$sel")" "${C_ACCENT}${C_BOLD}($n)${C_RESET}" "$(_ui_label "$label" "$n" "$sel")"
      # A description may span lines; keep them all indented under the label.
      [ "$desc" = "$opt" ] || printf '       %s\n' "${C_DIM}${desc//$'\n'/$'\n'       }${C_RESET}"
      printf '\n'
    done
    ui_footer
    _ui_prompt "1-$n, Enter, r, q" "$sel"
    case $UI_KEY in
      q | Q) ui_quit ;;
      r | R) return 10 ;;
      '')
        if [ -n "$sel" ]; then
          UI_CHOICE=$sel
          return 0
        fi
        ;;
      [1-9]) [ "$UI_KEY" -gt "$n" ] || sel=$UI_KEY ;;
    esac
  done
}

# "> " in front of the marked option, two spaces in front of the others.
_ui_marker() { # index marked
  if [ "$1" = "$2" ]; then printf '%s ' "${C_ACCENT}${C_BOLD}>${C_RESET}"; else printf '  '; fi
}

# A label, in the accent color when its option is marked.
_ui_label() { # label index marked
  if [ "$2" = "$3" ]; then printf '%s' "${C_ACCENT}${C_BOLD}$1${C_RESET}"; else printf '%s' "${C_BOLD}$1${C_RESET}"; fi
}

# The choice prompt, with the marked answer echoed after it. Reads one key into UI_KEY.
_ui_prompt() { # keys marked
  printf '  %s %s' "${C_BOLD}Choice [$1]:${C_RESET}" "${2:+${C_ACCENT}${C_BOLD}$2${C_RESET}  ${C_DIM}Enter to confirm${C_RESET}}"
  ui_key
  printf '\n'
}

# ui_checklist "Title" step total "note" "preselected indexes" "opt1" "opt2" ...
# Number keys toggle an option, Enter confirms (at least one must be on).
# Sets UI_CHECKED to the selected 1-based indexes, space-separated.
# Returns 10 on restart, exits on quit.
ui_checklist() {
  local title=$1 step=$2 total=$3 note=$4 n opt mark
  UI_CHECKED=$5
  shift 5
  while :; do
    ui_header "$step" "$total" "$title"
    [ -z "$note" ] || { ui_note "$note"; printf '\n'; }
    n=0
    for opt in "$@"; do
      n=$((n + 1))
      case " $UI_CHECKED " in *" $n "*) mark="${C_OK}[x]${C_RESET}" ;; *) mark='[ ]' ;; esac
      printf '  %s  %s %s\n\n' "${C_ACCENT}${C_BOLD}($n)${C_RESET}" "$mark" "${C_BOLD}$opt${C_RESET}"
    done
    printf '  %s\n' "${C_DIM}(1-$n)  Toggle.   (Enter)  Continue.${C_RESET}"
    ui_footer
    printf '  %s ' "${C_BOLD}Choice [1-$n, Enter, r, q]:${C_RESET}"
    ui_key
    printf '\n'
    case $UI_KEY in
      q | Q) ui_quit ;;
      r | R) return 10 ;;
      '') [ -z "$UI_CHECKED" ] || return 0 ;;
      [1-9])
        if [ "$UI_KEY" -le "$n" ]; then
          case " $UI_CHECKED " in
            *" $UI_KEY "*) UI_CHECKED=$(printf ' %s ' "$UI_CHECKED" | sed "s/ $UI_KEY / /; s/^ *//; s/ *$//") ;;
            *) UI_CHECKED="${UI_CHECKED:+$UI_CHECKED }$UI_KEY" ;;
          esac
        fi
        ;;
    esac
  done
}

ui_yesno() { # title step total question -> returns 0 yes / 1 no / 10 restart
  local title=$1 step=$2 total=$3 q=$4 sel=''
  while :; do
    ui_header "$step" "$total" "$title"
    printf '  %s\n\n' "$q"
    printf '%s%s  %s\n\n' "$(_ui_marker y "$sel")" "${C_ACCENT}${C_BOLD}(y)${C_RESET}" "$(_ui_label Yes y "$sel")"
    printf '%s%s  %s\n' "$(_ui_marker n "$sel")" "${C_ACCENT}${C_BOLD}(n)${C_RESET}" "$(_ui_label No n "$sel")"
    ui_footer
    _ui_prompt "y, n, Enter, r, q" "$sel"
    case $UI_KEY in
      y | Y) sel=y ;;
      n | N) sel=n ;;
      '')
        case $sel in
          y) return 0 ;;
          n) return 1 ;;
        esac
        ;;
      r | R) return 10 ;;
      q | Q) ui_quit ;;
    esac
  done
}

ui_quit() {
  printf '\n  %s\n' "Nothing was changed. Run ${C_BOLD}$HARNESS_ROOT/setup.sh${C_RESET} any time."
  exit 0
}
