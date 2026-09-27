# The SILT document on stdin as a TOML document: silt__to_toml. The root
# must be a table: a map, or the empty map, which is the empty document.
# A table's members are written in the document's order in two passes, the
# pairs first, "key = value" with an array or an inline table on one line,
# then each map as a table under its header and each list of maps as an
# array of tables, one header per element, a header's path dotted. A str is
# a basic string, a number and a bool are as written, a time is an offset
# date-time, and a null, which TOML has no spelling for, is the map ADR.20
# gives a value the target cannot carry. Refused, naming the line: a root
# that is a list or a scalar, a line out of place in the tree or under a
# leaf, an index out of order, a key its map already holds, an index under
# a map or a key under a list, a keyless line that is not the whole
# document, and a type TOML has no spelling for. The lines are kept first,
# since a table is written in two passes. Loaded after awk/lines.awk and
# spell.awk beside this one.
#
#   0."name":str="x"                                          name = "x"
#   0."owner":map                                         ->
#   1."dob":time-rfc3339-utc=1979-05-27T07:32:00.000000000Z   [owner]
#                                                             dob = 1979-05-27T07:32:00.000000000Z

# Ends the run naming the line that cannot be written.
function refuse_line(why, i) {
  refuse("line " i ": " why ": " T_LINE[i])
}

# Reads the first line: a keyless map is the empty document, any other
# keyless line and an index make a root TOML cannot spell, and a name
# opens the root table.
function open_root() {
  if (T_KEY[1] == "" && T_TYPE[1] == "map") {
    EMPTY_ROOT = 1
    return
  }
  if (T_KEY[1] == "" || !is_name(T_KEY[1])) {
    refuse_line("a document TOML cannot spell, its root being no table", 1)
  }

  open_children(0, "map")
}

# Makes the children at <depth> those of a collection of <kind>.
function open_children(depth, kind) {
  C_KIND[depth] = kind
  C_COUNT[depth] = 0
  C_SERIAL[depth] = ++SERIALS
}

# Refuses line i where it cannot follow line i-1: after a keyless line,
# more than a level deeper, or under a leaf.
function check_place(i) {
  if (EMPTY_ROOT || T_KEY[i] == "") {
    refuse_line("a keyless line that is not the whole document", i)
  }
  if (T_DEPTH[i] > T_DEPTH[i - 1] + 1) {
    refuse_line("out of place in the tree", i)
  }
  if (T_DEPTH[i] == T_DEPTH[i - 1] + 1 && !opens(i - 1)) {
    refuse_line("under a leaf, which takes no children", i)
  }
}

# Whether line i opens a collection its children fill.
function opens(i) {
  return T_TYPE[i] == "map" || T_TYPE[i] == "list"
}

# Checks line i's key against the collection its depth puts it in: a name
# the map does not hold yet under a map, and the next index under a list.
# Counts the member.
function check_key(i) {
  if (C_KIND[T_DEPTH[i]] == "map") {
    check_map_key(i)
  } else {
    check_index(i)
  }

  C_COUNT[T_DEPTH[i]]++
}

# Refuses an index under a map, and a key its map already holds.
function check_map_key(i) {
  if (!is_name(T_KEY[i])) {
    refuse_line("an index under a map", i)
  }
  if ((C_SERIAL[T_DEPTH[i]], unwrap(T_KEY[i])) in HELD) {
    refuse_line("a key its map already holds", i)
  }

  HELD[C_SERIAL[T_DEPTH[i]], unwrap(T_KEY[i])] = 1
}

# Refuses a name under a list, and an index that is not the next one.
function check_index(i) {
  if (is_name(T_KEY[i])) {
    refuse_line("a key under a list", i)
  }
  if (T_KEY[i] !~ /^(0|[1-9][0-9]*)$/ || T_KEY[i] + 0 != C_COUNT[T_DEPTH[i]]) {
    refuse_line("an index out of order, " C_COUNT[T_DEPTH[i]] " expected", i)
  }
}

# Checks line i's type and value: a collection and a null take no value, a
# leaf takes one, and a type TOML has no spelling for is refused. A
# collection opens the children at the next depth.
function check_value(i) {
  if (opens(i) || T_TYPE[i] == "null") {
    if (T_LEAF[i]) {
      refuse_line("a value on a line that takes none", i)
    }
  } else if (T_TYPE[i] ~ /^(str|int|float|bool|time-rfc3339-utc)$/) {
    if (!T_LEAF[i]) {
      refuse_line("a leaf with no value", i)
    }
  } else {
    refuse_line("a type TOML has no spelling for", i)
  }

  if (opens(i)) {
    open_children(T_DEPTH[i] + 1, T_TYPE[i])
  }
}

# Checks every line kept against the tree they spell.
function check_lines(__i) {
  open_root()

  for (__i = 1; __i <= T_N; __i++) {
    if (__i > 1) {
      check_place(__i)
    }
    if (!EMPTY_ROOT) {
      check_key(__i)
    }

    check_value(__i)
  }
}

# The first line past line i and every line under it.
function past(i, __j) {
  __j = i + 1

  while (__j <= T_N && T_DEPTH[__j] > T_DEPTH[i]) {
    __j++
  }

  return __j
}

# Fills <out> with the lines of the members of the collection at line i,
# the root's when i is 0, and returns how many.
function members_of(i, out, __end, __j, __n) {
  __end = (i == 0) ? T_N + 1 : past(i)
  __n = 0

  for (__j = i + 1; __j < __end; __j = past(__j)) {
    out[++__n] = __j
  }

  return __n
}

# Whether line i is a member written as a pair: anything but a map and a
# list of maps, which take headers.
function is_pair(i) {
  return T_TYPE[i] != "map" && !is_table_array(i)
}

# Whether line i is a list of maps with at least one, which is written as
# an array of tables.
function is_table_array(i, __members, __n, __k) {
  if (T_TYPE[i] != "list") {
    return 0
  }

  __n = members_of(i, __members)
  for (__k = 1; __k <= __n; __k++) {
    if (T_TYPE[__members[__k]] != "map") {
      return 0
    }
  }

  return __n > 0
}

# Prints a line of the document.
function emit_line(text) {
  print text
  PRINTED = 1
}

# Prints a header, a blank line before it when it is not the document's
# first line.
function emit_header(header) {
  if (PRINTED) {
    print ""
  }

  emit_line(header)
}

# The line's value as it is written after "key = " or inside a collection:
# a str as a basic string, a null as ADR.20's map, a collection between its
# brackets or braces, and any other as written.
function value_text(i) {
  if (opens(i)) {
    return collection_text(i)
  }
  if (T_TYPE[i] == "str") {
    return toml_basic(unwrap(T_VALUE[i]))
  }
  if (T_TYPE[i] == "null") {
    return "{ format = \"strata\", spelling = \"null\" }"
  }

  return T_VALUE[i]
}

# The collection at line i on one line: its members between brackets as an
# array, or between braces as an inline table, and "[]" or "{}" empty.
function collection_text(i, __members, __n, __k, __out) {
  __n = members_of(i, __members)
  if (__n == 0) {
    return (T_TYPE[i] == "map") ? "{}" : "[]"
  }

  __out = ""
  for (__k = 1; __k <= __n; __k++) {
    __out = __out ((__k > 1) ? ", " : "") member_text(i, __members[__k])
  }

  return (T_TYPE[i] == "map") ? "{ " __out " }" : "[" __out "]"
}

# Member line j of the collection at line i, inline: its key and value
# under a map, its value alone under a list.
function member_text(i, j) {
  if (T_TYPE[i] == "map") {
    return toml_key(unwrap(T_KEY[j])) " = " value_text(j)
  }

  return value_text(j)
}

# Writes the table at line i, the root's when i is 0, whose header path is
# <path>: its pairs first, then its tables and arrays of tables under their
# headers.
function write_table(i, path, __members, __n, __k) {
  __n = members_of(i, __members)

  for (__k = 1; __k <= __n; __k++) {
    if (is_pair(__members[__k])) {
      emit_line(toml_key(unwrap(T_KEY[__members[__k]])) " = " value_text(__members[__k]))
    }
  }

  for (__k = 1; __k <= __n; __k++) {
    if (!is_pair(__members[__k])) {
      write_headed(__members[__k], path)
    }
  }
}

# Writes the member at line i of the table whose header path is <path>
# under a header of its own: a map as a table, and a list of maps as an
# array of tables, one header per element.
function write_headed(i, path, __path, __members, __n, __k) {
  __path = path ((path == "") ? "" : ".") toml_key(unwrap(T_KEY[i]))

  if (T_TYPE[i] == "map") {
    emit_header("[" __path "]")
    write_table(i, __path)
    return
  }

  __n = members_of(i, __members)
  for (__k = 1; __k <= __n; __k++) {
    emit_header("[[" __path "]]")
    write_table(__members[__k], __path)
  }
}

# Keeps the line and its parts for END.
function main() {
  parse($0)
  T_N++
  T_LINE[T_N] = $0
  T_DEPTH[T_N] = DEPTH
  T_KEY[T_N] = KEY
  T_TYPE[T_N] = TYPE
  T_VALUE[T_N] = VALUE
  T_LEAF[T_N] = LEAF
}

BEGIN {
  T_N = 0
  EMPTY_ROOT = 0
  PRINTED = 0
  SERIALS = 0
}

END {
  if (REFUSED) {
    exit 1
  }
  if (T_N == 0) {
    refuse("an empty document holds no value")
  }

  check_lines()
  if (!EMPTY_ROOT) {
    write_table(0, "")
  }
}

{ main() }
