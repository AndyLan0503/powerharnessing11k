# Minimal template engine. Variables come from the environment with an HV_
# prefix: {{PROJECT_NAME}} -> ENVIRON["HV_PROJECT_NAME"].
#
#   {{NAME}}                     substitute (unknown names are left as-is)
#   {{#if NAME}} ... {{/if}}     keep block when NAME is truthy
#   {{#unless NAME}} ... {{/if}} keep block when NAME is falsy
#
# Directives must sit alone on their line. Blocks nest. A value is truthy when
# it is non-empty and not one of 0/false/no/off.

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
    } else {
      out = out substr(line, 1, start + 1 + cl + 1)
    }
    line = substr(rest, cl + 2)
  }
  return out line
}

{
  if (match($0, /^[ \t]*\{\{#if [A-Z][A-Z0-9_]*\}\}[ \t]*$/)) {
    s = $0; sub(/^[ \t]*\{\{#if /, "", s); sub(/\}\}[ \t]*$/, "", s)
    keep[++depth] = truthy(s); next
  }
  if (match($0, /^[ \t]*\{\{#unless [A-Z][A-Z0-9_]*\}\}[ \t]*$/)) {
    s = $0; sub(/^[ \t]*\{\{#unless /, "", s); sub(/\}\}[ \t]*$/, "", s)
    keep[++depth] = !truthy(s); next
  }
  if (match($0, /^[ \t]*\{\{\/if\}\}[ \t]*$/)) {
    if (depth > 0) depth--
    next
  }
  if (active()) print subst($0)
}

END {
  if (depth != 0) { print "render: unbalanced {{#if}} in " FILENAME > "/dev/stderr"; exit 3 }
}
