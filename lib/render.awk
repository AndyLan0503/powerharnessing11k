# Minimal template engine. Variables come from the environment with an HV_
# prefix: {{PROJECT_NAME}} -> ENVIRON["HV_PROJECT_NAME"].
#
#   {{NAME}}                     substitute (unknown names are left as-is)
#   {{#if NAME}} ... {{/if}}     keep block when NAME is truthy
#   {{#unless NAME}} ... {{/if}} keep block when NAME is falsy
#
#   {{> file}}                   include file (relative to the template's
#                                module), up to five levels deep
#
# Directives must sit alone on their line, except {{#if}}/{{#unless}} ...
# {{/if}} pairs within one line. Blocks nest. A value is truthy when it is
# non-empty and not one of 0/false/no/off.

function truthy(name,    v) {
  if (!(("HV_" name) in ENVIRON)) return 0
  v = tolower(ENVIRON["HV_" name])
  return !(v == "" || v == "0" || v == "false" || v == "no" || v == "off")
}

function active(    i) {
  for (i = 1; i <= depth; i++) if (!keep[i]) return 0
  return 1
}

# Inline form, same line, not nested: "a{{#if X}}b{{/if}}c".
function inline_ifs(line,    out, open, tag, kw, name, body, cl) {
  out = ""
  while (match(line, /\{\{#(if|unless) [A-Z][A-Z0-9_]*\}\}/)) {
    open = RSTART; tag = substr(line, RSTART, RLENGTH)
    kw = (substr(tag, 4, 2) == "if") ? "if" : "unless"
    name = substr(tag, (kw == "if") ? 7 : 11, RLENGTH - ((kw == "if") ? 8 : 12))
    body = substr(line, open + RLENGTH)
    cl = index(body, "{{/if}}")
    if (cl == 0) break
    out = out substr(line, 1, open - 1)
    if (truthy(name) == (kw == "if")) out = out substr(body, 1, cl - 1)
    line = substr(body, cl + 7)
  }
  return out line
}

function subst(line,    out, start, rest, cl, name) {
  line = inline_ifs(line)
  out = ""
  while ((start = index(line, "{{")) > 0) {
    rest = substr(line, start + 2)
    cl = index(rest, "}}")
    if (cl == 0) break
    name = substr(rest, 1, cl - 1)
    if (name ~ /^[A-Z][A-Z0-9_]*$/ && (("HV_" name) in ENVIRON)) {
      out = out substr(line, 1, start - 1) ENVIRON["HV_" name]
      line = substr(rest, cl + 2)
    } else {
      # Not ours (e.g. GitHub's ${{ ... }}): keep the braces and keep looking,
      # so one of our names inside such an expression is still filled in.
      out = out substr(line, 1, start + 1)
      line = rest
    }
  }
  return out line
}

# One template line: directives open and close blocks, the rest is kept or
# dropped by the blocks around it.
function render(line,    s) {
  if (match(line, /^[ \t]*\{\{#if [A-Z][A-Z0-9_]*\}\}[ \t]*$/)) {
    s = line; sub(/^[ \t]*\{\{#if /, "", s); sub(/\}\}[ \t]*$/, "", s)
    keep[++depth] = truthy(s); return
  }
  if (match(line, /^[ \t]*\{\{#unless [A-Z][A-Z0-9_]*\}\}[ \t]*$/)) {
    s = line; sub(/^[ \t]*\{\{#unless /, "", s); sub(/\}\}[ \t]*$/, "", s)
    keep[++depth] = !truthy(s); return
  }
  if (match(line, /^[ \t]*\{\{\/if\}\}[ \t]*$/)) {
    if (depth > 0) depth--
    return
  }
  if (active()) print subst(line)
}

# {{> file}} alone on a line includes file (relative to RENDER_DIR) in its
# place. An empty file is fine; one that cannot be read fails the render.
function expand(path, level,    l, f, r) {
  if (level > 5) { print "render: partials nested too deeply at " path > "/dev/stderr"; exit 3 }
  while ((r = (getline l < path)) > 0) {
    if (l ~ /^\{\{> [^}]+\}\}[ \t]*$/) {
      f = l; sub(/^\{\{> /, "", f); sub(/\}\}[ \t]*$/, "", f)
      expand(ENVIRON["RENDER_DIR"] "/" f, level + 1)
    } else {
      render(l)
    }
  }
  close(path)
  if (r < 0) { print "render: cannot read " path > "/dev/stderr"; exit 3 }
}

# Usage: RENDER_DIR=DIR awk -f render.awk TEMPLATE
BEGIN {
  expand(ARGV[1], 0)
  if (depth != 0) { print "render: unbalanced {{#if}} in " ARGV[1] > "/dev/stderr"; exit 3 }
  exit
}
