# shellcheck shell=bash
# Terminal UI for the configuration wizard, in the spirit of `p10k configure`:
# one question per screen, single-key answers, (r)estart and (q)uit everywhere.

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
  printf '%s\n' "${C_ACCENT}${C_BOLD}"
  printf '%s\n' '   _                                    '
  printf '%s\n' '  | |__   __ _ _ __ _ __   ___  ___ ___ '
  printf '%s\n' "  | '_ \\ / _\` | '__| '_ \\ / _ \\/ __/ __|"
  # shellcheck disable=SC1003
  printf '%s\n' '  | | | | (_| | |  | | | |  __/\__ \__ \'
  printf '%s\n' '  |_| |_|\__,_|_|  |_| |_|\___||___/___/'
  printf '%s\n' "${C_RESET}"
  printf '  %s\n\n' "${C_DIM}agentic harness configurator  v$(cat "$HARNESS_ROOT/VERSION")${C_RESET}"
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
# Shows numbered options; sets UI_CHOICE to the 1-based index.
# Returns 10 on restart, exits on quit.
ui_choose() {
  local title=$1 step=$2 total=$3
  shift 3
  local n=0 opt label desc
  while :; do
    ui_header "$step" "$total" "$title"
    n=0
    for opt in "$@"; do
      n=$((n + 1))
      label=${opt%%|*}
      desc=${opt#*|}
      printf '  %s  %s\n' "${C_ACCENT}${C_BOLD}($n)${C_RESET}" "${C_BOLD}$label${C_RESET}"
      [ "$desc" = "$opt" ] || printf '       %s\n' "${C_DIM}$desc${C_RESET}"
      printf '\n'
    done
    ui_footer
    printf '  %s ' "${C_BOLD}Choice [1-$n, r, q]:${C_RESET}"
    ui_key
    printf '\n'
    case $UI_KEY in
      q | Q) ui_quit ;;
      r | R) return 10 ;;
      [1-9])
        if [ "$UI_KEY" -le "$n" ]; then
          UI_CHOICE=$UI_KEY
          return 0
        fi
        ;;
    esac
  done
}

ui_yesno() { # title step total question -> returns 0 yes / 1 no / 10 restart
  local title=$1 step=$2 total=$3 q=$4
  while :; do
    ui_header "$step" "$total" "$title"
    printf '  %s\n\n' "$q"
    printf '  %s  Yes\n\n' "${C_ACCENT}${C_BOLD}(y)${C_RESET}"
    printf '  %s  No\n' "${C_ACCENT}${C_BOLD}(n)${C_RESET}"
    ui_footer
    printf '  %s ' "${C_BOLD}Choice [ynrq]:${C_RESET}"
    ui_key
    printf '\n'
    case $UI_KEY in
      y | Y) return 0 ;;
      n | N) return 1 ;;
      r | R) return 10 ;;
      q | Q) ui_quit ;;
    esac
  done
}

ui_quit() {
  printf '\n  %s\n' "Nothing was changed. Run ${C_BOLD}$HARNESS_ROOT/setup.sh${C_RESET} any time."
  exit 0
}
