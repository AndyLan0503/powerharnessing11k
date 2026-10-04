# shellcheck shell=bash

# render_template SRC DEST — expand a template using the exported HV_* vars.
# A line of the form "{{> path}}" is first replaced by the contents of
# $MODULE_DIR/path (one level, no recursion) so modules can share fragments.
render_template() {
  local dir=${MODULE_DIR:-$(dirname "$1")}
  awk -v dir="$dir" '
    /^\{\{> [^}]+\}\}[ \t]*$/ {
      f = $0; sub(/^\{\{> /, "", f); sub(/\}\}[ \t]*$/, "", f)
      path = dir "/" f
      if ((getline l < path) <= 0) { print "render: missing partial " path > "/dev/stderr"; exit 3 }
      print l
      while ((getline l < path) > 0) print l
      close(path); next
    }
    { print }' "$1" | awk -f "$HARNESS_ROOT/lib/render.awk" >"$2"
}
