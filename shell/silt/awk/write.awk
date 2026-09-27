# The SILT writer every translator into SILT drives: a document built one
# event at a time, a collection opened and closed and a scalar written under
# a key, its lines kept and printed in canonical order once the document is
# whole. The writer keeps which collections are open, so a caller under a
# map names its member's key as a JSON string literal and a caller under a
# list names nothing, the index being the writer's. A map handed a key twice
# is refused. Loaded after lines.awk and order.awk; a program's BEGIN calls
# order_begin() and its END print_ordered().
#
#   {"a":[1,"x"]}    open_collection("map", "")          ->  0."a":list
#                    open_collection("list", "\"a\"")        1.0:int=1
#                    write_number("", "1")                   1.1:str="x"
#                    write_scalar("", "str", "\"x\"")
#                    close_collection()
#                    close_collection()

# Opens a collection, a map or a list, as the member <key> of the map open,
# the next element of the list open, or the document's root when none is
# open. A root collection's own line is written only when it closes empty,
# since a full one is spelled by its members at depth 0 alone.
function open_collection(kind, key) {
  if (OPEN == 0) {
    ROOT_KIND = kind
    push_collection(kind, 0)
    return
  }

  take(OPEN_DEPTH[OPEN] "." member_key(key) ":" kind)
  push_collection(kind, OPEN_DEPTH[OPEN] + 1)
}

# Makes a collection the one open, its children at <depth>.
function push_collection(kind, depth) {
  OPEN++
  OPEN_KIND[OPEN] = kind
  OPEN_DEPTH[OPEN] = depth
  OPEN_COUNT[OPEN] = 0
  OPEN_SERIAL[OPEN] = ++SERIALS
}

# Closes the collection open. The root closing with nothing in it is the
# keyless line of an empty collection.
function close_collection() {
  if (OPEN == 1 && OPEN_COUNT[1] == 0) {
    take("0.:" ROOT_KIND)
  }

  OPEN--
}

# Writes a scalar as the member <key> of the map open, the next element of
# the list open, or the whole document when none is open. A null has no
# value; every other type's value is given as the line spells it, a str as
# its JSON literal.
function write_scalar(key, type, value, __tail) {
  __tail = (type == "null") ? "" : "=" value

  if (OPEN == 0) {
    take("0.:" type __tail)
    return
  }

  take(OPEN_DEPTH[OPEN] "." member_key(key) ":" type __tail)
}

# The key the next child of the collection open is written under: the
# index under a list, and under a map the key given, refused when the map
# already holds it. Counts the child.
function member_key(key) {
  OPEN_COUNT[OPEN]++

  if (OPEN_KIND[OPEN] == "list") {
    return OPEN_COUNT[OPEN] - 1
  }

  if ((OPEN_SERIAL[OPEN], unwrap(key)) in HELD) {
    refuse("a key its map already holds: " key)
  }
  HELD[OPEN_SERIAL[OPEN], unwrap(key)] = 1

  return key
}

# Writes a number under <key>: an int when its text is ADR.20's int pattern
# and a float when it is the float pattern, the text kept as written.
function write_number(key, text) {
  write_scalar(key, number_type(text), text)
}

# The type a number's text spells by ADR.20's patterns, int or float.
# Refuses any other spelling, an int outside 64 bits, and a float binary64
# cannot hold.
function number_type(text) {
  if (text ~ /^-?(0|[1-9][0-9]*)$/) {
    refuse_int_outside_64_bits(text)
    return "int"
  }

  if (text ~ /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/ || text ~ /^(-?inf|nan)$/) {
    refuse_float_outside_binary64(text)
    return "float"
  }

  refuse("a number spelled outside ADR.20's patterns: " text)
}

# Refuses an int past what 64 bits hold. The digits are compared as text
# against the limit's, since awk's own numbers stop being exact at 2^53.
function refuse_int_outside_64_bits(text, __digits, __limit) {
  __digits = text
  sub(/^-/, "", __digits)
  __limit = (text ~ /^-/) ? "9223372036854775808" : "9223372036854775807"

  if (length(__digits) > length(__limit)) {
    refuse("an int outside 64 bits: " text)
  }
  if (length(__digits) == length(__limit) && __digits > __limit) {
    refuse("an int outside 64 bits: " text)
  }
}

# Refuses a float past what binary64 holds, which awk's arithmetic reads as
# an infinity; inf, -inf and nan are held as they are.
function refuse_float_outside_binary64(text, __value) {
  if (text ~ /^(-?inf|nan)$/) {
    return
  }

  __value = text + 0
  if (__value > 1.7976931348623157e308 || __value < -1.7976931348623157e308) {
    refuse("a float outside binary64: " text)
  }
}
