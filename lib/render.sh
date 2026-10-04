# shellcheck shell=bash

# render_template SRC DEST — expand a template using the exported HV_* vars.
# A line of the form "{{> path}}" is first replaced by the contents of
# $MODULE_DIR/path. Partials may include partials, up to 5 levels deep.
render_template() {
  local dir=${MODULE_DIR:-$(dirname "$1")}
  awk -v dir="$dir" '
    function expand(path, depth,    l, f, n) {
      if (depth > 5) { print "render: partials nested too deeply at " path > "/dev/stderr"; exit 3 }
      n = 0
      while ((getline l < path) > 0) {
        n++
        if (l ~ /^\{\{> [^}]+\}\}[ \t]*$/) {
          f = l; sub(/^\{\{> /, "", f); sub(/\}\}[ \t]*$/, "", f)
          expand(dir "/" f, depth + 1)
        } else {
          print l
        }
      }
      close(path)
      if (n == 0) { print "render: missing or empty partial " path > "/dev/stderr"; exit 3 }
    }
    BEGIN { expand(ARGV[1], 0); exit }' "$1" | awk -f "$HARNESS_ROOT/lib/render.awk" >"$2"
}
