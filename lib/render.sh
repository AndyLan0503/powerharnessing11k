# shellcheck shell=bash

# render_template SRC DEST — expand a template using the exported HV_* vars.
# A line of the form "{{> path}}" is first replaced by the contents of
# $MODULE_DIR/path. Partials may include partials, up to 5 levels deep.
render_template() {
  local dir=${MODULE_DIR:-}
  [ -n "$dir" ] || dir=${1%/*}
  # The directory goes through the environment: awk -v would read backslashes
  # in it as escapes.
  RENDER_DIR=$dir awk -f "$HARNESS_ROOT/lib/render.awk" "$1" >"$2"
}
