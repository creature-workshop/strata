# The SILT document on stdin as one line of JSON: silt__to_json. With
# SILT_INDENT set to a number of spaces, the JSON is on several lines, each
# member on its own line and indented by that many spaces for each level:
# silt__dump. Each line
# is written as it is read, a str's literal, a number's text and a key
# copied as written, a time as a string, and a float JSON cannot spell, inf,
# -inf or nan, as the map ADR.20 gives it; the collections a line leaves
# behind are closed before it is written. Refused, naming the line: a line
# out of place in the tree or under a leaf, an index out of order, a key its
# map already holds, an index under a map or a key under a list, a keyless
# line that is not the whole document, a type JSON has no spelling for, and
# an empty document. Loaded after lines.awk.
#
#   0."a":null
#   0."b":list
#   1.0:int=1
#   1.1:str="x"   ->  {"a":null,"b":[1,"x"]}
#
#   SILT_INDENT=2   ->  {
#                         "a": null,
#                         "b": [
#                           1,
#                           "x"
#                         ]
#                       }

# Ends the run naming the line that cannot be written.
function refuse_line(why) {
  refuse("line " NR ": " why ": " $0)
}

# Reads the first line: a keyless one is the whole document, and any other
# opens the root as the map or the list its key says.
function open_root() {
  if (DEPTH != 0) {
    refuse_line("out of place in the tree")
  }

  if (KEY == "") {
    KEYLESS = 1
  } else {
    DEPTH = -1
    open_child(is_name(KEY) ? "map" : "list")
    DEPTH = 0
  }
}

# Refuses a line that cannot follow the one before it: one after a keyless
# line, one more than a level deeper, and one under a leaf.
function check_place() {
  if (KEYLESS || KEY == "") {
    refuse_line("a keyless line that is not the whole document")
  }
  if (DEPTH > LAST_DEPTH + 1) {
    refuse_line("out of place in the tree")
  }
  if (DEPTH == LAST_DEPTH + 1 && !LAST_OPENS) {
    refuse_line("under a leaf, which takes no children")
  }
}

# Starts a new line for a value that sits <levels> collections deep, when
# the JSON is written on several lines, and does nothing when it is not.
function start_line(levels, __i) {
  if (INDENT == "") {
    return
  }

  printf "\n"
  for (__i = 0; __i < levels * INDENT; __i++) {
    printf " "
  }
}

# Closes every collection deeper than the line. A collection that holds a
# member closes on a line of its own.
function close_behind() {
  while (OPEN > DEPTH) {
    if (COUNT[OPEN] > 0) {
      start_line(OPEN)
    }
    printf "%s", (KIND[OPEN] == "map") ? "}" : "]"
    OPEN--
  }
}

# Writes the comma between two members of one collection, and counts the
# member.
function write_separator() {
  if (KEYLESS) {
    return
  }

  if (COUNT[DEPTH] > 0) {
    printf ","
  }
  COUNT[DEPTH]++
  start_line(DEPTH + 1)
}

# Writes the member's key: under a map its literal as written, refused when
# the map already holds it; under a list nothing, the index checked against
# the one expected.
function write_key() {
  if (KEYLESS) {
    return
  }

  if (KIND[DEPTH] == "map") {
    write_map_key()
  } else {
    check_index()
  }
}

# Writes a map member's key, refused when it is an index or one the map
# already holds.
function write_map_key() {
  if (!is_name(KEY)) {
    refuse_line("an index under a map")
  }
  if ((SERIAL[DEPTH], unwrap(KEY)) in HELD) {
    refuse_line("a key its map already holds")
  }

  HELD[SERIAL[DEPTH], unwrap(KEY)] = 1
  printf "%s:%s", KEY, (INDENT == "") ? "" : " "
}

# Refuses a list element whose key is a name, or an index that is not the
# next one.
function check_index() {
  if (is_name(KEY)) {
    refuse_line("a key under a list")
  }
  if (KEY + 0 != COUNT[DEPTH] - 1 || KEY !~ /^(0|[1-9][0-9]*)$/) {
    refuse_line("an index out of order, " (COUNT[DEPTH] - 1) " expected")
  }
}

# Opens a collection whose children sit one level deeper than the line, the
# root's at depth 0.
function open_child(kind) {
  printf "%s", (kind == "map") ? "{" : "["
  OPEN = DEPTH + 1
  KIND[OPEN] = kind
  COUNT[OPEN] = 0
  SERIAL[OPEN] = ++SERIALS
}

# Writes a collection: its opener, or both brackets for an empty document.
function write_collection() {
  if (LEAF) {
    refuse_line("a value on a line that takes none")
  }

  if (KEYLESS) {
    printf "%s", (TYPE == "map") ? "{}" : "[]"
  } else {
    open_child(TYPE)
  }
}

# Writes a leaf's value: a str's literal, an int's, a bool's and a float's
# text as written, and a time as a string.
function write_leaf() {
  if (!LEAF) {
    refuse_line("a leaf with no value")
  }

  if (TYPE == "time-rfc3339-utc") {
    printf "\"%s\"", VALUE
  } else if (TYPE == "float") {
    printf "%s", float_text()
  } else {
    printf "%s", VALUE
  }
}

# A float's text as JSON spells it: inf, -inf and nan, which JSON has no
# number for, as the map ADR.20 gives them; any other as written.
function float_text() {
  if (VALUE ~ /^(-?inf|nan)$/) {
    return "{\"format\":\"strata\",\"spelling\":\"" VALUE "\"}"
  }

  return VALUE
}

# Writes a null.
function write_null() {
  if (LEAF) {
    refuse_line("a value on a line that takes none")
  }

  printf "null"
}

# Writes the line's value by its type.
function write_value() {
  if (TYPE == "map" || TYPE == "list") {
    write_collection()
  } else if (TYPE == "null") {
    write_null()
  } else if (TYPE ~ /^(str|int|float|bool|time-rfc3339-utc)$/) {
    write_leaf()
  } else {
    refuse_line("a type JSON has no spelling for")
  }
}

# One line: placed in the tree, then its separator, its key and its value.
function main() {
  parse($0)

  if (NR == 1) {
    open_root()
  } else {
    check_place()
    close_behind()
  }

  write_separator()
  write_key()
  write_value()

  LAST_DEPTH = DEPTH
  LAST_OPENS = (TYPE == "map" || TYPE == "list") && !KEYLESS
}

BEGIN {
  INDENT = ENVIRON["SILT_INDENT"]
  OPEN = 0
  KEYLESS = 0
  LAST_DEPTH = 0
  LAST_OPENS = 0
  SERIALS = 0
}

END {
  if (REFUSED) {
    exit 1
  }
  if (NR == 0) {
    refuse("an empty document holds no value")
  }

  DEPTH = -1
  if (!KEYLESS) {
    close_behind()
  }
  print ""
}

{ main() }
