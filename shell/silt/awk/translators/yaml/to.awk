# The SILT document on stdin as a YAML document in block style:
# silt__to_yaml. A map's keys keep their order, a nested collection is
# indented by two, and an empty one is written "{}" or "[]". A string is
# written plain only where it reads back as the same string, as a literal
# block when it runs over lines, and in double quotes, as its literal
# already spells it, everywhere else. The lines are kept first, since a
# collection is written on its own line only when its next line is deeper.
# Loaded after lines.awk, and lines.awk and scalars.awk beside this one.
#
#   0."jobs":list
#   1.0:map
#   2."name":str="test"    ->  jobs:
#   2."needs":list               - name: test
#   0."on":str="push"              needs: []
#                              "on": push

# Ends the run naming the line that cannot be written.
function refuse_line(why, line) {
  refuse("line " NR ": " why ": " line)
}

# n spaces.
function spaces(n) {
  return sprintf("%" n "s", "")
}

# Text as YAML writes it, as a key or as a value: plain where it reads back
# as itself, its literal otherwise.
function string_yaml(text, literal) {
  if (is_plain_safe(text)) {
    return text
  }

  return literal
}

# A scalar's value as YAML writes it on one line: a str plain or in its
# literal, a null as the word, a float JSON cannot spell as .inf or .nan, a
# time in quotes, and any other as written.
function scalar_yaml() {
  if (TYPE == "str") {
    return string_yaml(unwrap(VALUE), VALUE)
  }
  if (TYPE == "null") {
    return "null"
  }
  if (TYPE == "float" && VALUE ~ /^(-?inf|nan)$/) {
    return (VALUE == "nan") ? ".nan" : ((VALUE == "inf") ? ".inf" : "-.inf")
  }
  if (TYPE == "time-rfc3339-utc") {
    return "\"" VALUE "\""
  }

  return VALUE
}

# The mark that opens a literal block holding the text: "|-" when the text
# ends with no line break, "|+" when it ends with several, "|" for the one.
function block_header(text) {
  if (text !~ /\n$/) {
    return "|-"
  }

  return (text ~ /\n\n$/) ? "|+" : "|"
}

# Prints a string as a literal block after <head>, its lines at <indent>.
function write_literal(head, text, indent, __n, __i, __lines) {
  print head block_header(text)
  sub(/\n$/, "", text)

  __n = split(text, __lines, "\n")
  for (__i = 1; __i <= __n; __i++) {
    print (__lines[__i] == "") ? "" : spaces(indent) __lines[__i]
  }
}

# Prints a scalar after <head>: on head's line, or as a literal block under
# it when it is a str that runs over lines, at <indent>.
function write_scalar_line(head, indent) {
  if (TYPE == "str" && is_block_safe(unwrap(VALUE))) {
    write_literal(head, unwrap(VALUE), indent)
    return
  }

  print head scalar_yaml()
}

# The start of the line's text: the lead its parent left for its first
# member, or the parent's indentation, then a dash under a list or the key
# and its colon under a map.
function head_of(__head) {
  __head = (C_LEAD[DEPTH] != "") ? C_LEAD[DEPTH] : spaces(C_INDENT[DEPTH])
  C_LEAD[DEPTH] = ""

  if (C_KIND[DEPTH] == "list") {
    return __head "- "
  }

  return __head string_yaml(unwrap(KEY), KEY) ": "
}

# Opens the collection on line i after <head>: its brackets when line i+1
# is not deeper, since it is then empty; otherwise its members follow, one
# level in, the first on the dash's own line when the parent is a list.
function write_collection(i, head) {
  if (i == T_N || T_DEPTH[i + 1] <= DEPTH) {
    print head ((TYPE == "map") ? "{}" : "[]")
    return
  }

  C_KIND[DEPTH + 1] = TYPE
  C_INDENT[DEPTH + 1] = C_INDENT[DEPTH] + 2
  C_LEAD[DEPTH + 1] = ""

  if (C_KIND[DEPTH] == "list") {
    C_LEAD[DEPTH + 1] = head
  } else {
    sub(/ $/, "", head)
    print head
  }
}

# Prints a keyless line, the whole document: a scalar, or the brackets of an
# empty collection.
function write_keyless() {
  if (TYPE == "map" || TYPE == "list") {
    print (TYPE == "map") ? "{}" : "[]"
    return
  }

  write_scalar_line("", 2)
}

# Opens the root from the first line: a keyless one is the whole document,
# and any other makes the root the map or the list its key says.
function open_root() {
  KEYLESS = (KEY == "")
  C_KIND[0] = is_name(KEY) ? "map" : "list"
  C_INDENT[0] = 0
  C_LEAD[0] = ""
}

# Prints line i of the document, its place in the tree checked against the
# line before it.
function write_line(i, __head) {
  parse(T_LINE[i])

  if (i == 1) {
    open_root()
  } else if (KEYLESS || KEY == "") {
    refuse_line("a keyless line that is not the whole document", T_LINE[i])
  } else if (DEPTH > T_DEPTH[i - 1] + 1) {
    refuse_line("out of place in the tree", T_LINE[i])
  }

  if (KEYLESS) {
    write_keyless()
  } else if (TYPE == "map" || TYPE == "list") {
    write_collection(i, head_of())
  } else {
    write_scalar_line(head_of(), C_INDENT[DEPTH] + 2)
  }
}

# Keeps the line, and its depth for the look ahead, for END.
function main() {
  T_LINE[++T_N] = $0
  parse($0)
  T_DEPTH[T_N] = DEPTH
}

BEGIN {
  T_N = 0
}

END {
  if (REFUSED) {
    exit 1
  }
  if (T_N == 0) {
    refuse("an empty document holds no value")
  }

  for (T_I = 1; T_I <= T_N; T_I++) {
    write_line(T_I)
  }
}

{ main() }
