# The document with the value in SILT_SPILL placed at the path in
# SILT_SEGMENTS: silt__set past the threshold. The member there is replaced
# with everything under it; a missing one is added at the end of its parent,
# with missing parents created as maps, or lists where the next segment is
# an index. A refusal ends the run with the shell's message and status 1.

# Reads the value document from the spill file into VALUE_LINE[1..VALUES].
function read_value(__line) {
  VALUES = 0

  while ((getline __line < ENVIRON["SILT_SPILL"]) > 0) {
    VALUE_LINE[++VALUES] = __line
  }

  close(ENVIRON["SILT_SPILL"])
}

# Handles one parsed line before the value is placed: a shallower line closes
# the parent, so the value goes in before it; a line that is not the segment
# is kept; the segment itself is replaced when the path ends there, and
# descended into when it does not.
function match_line(line) {
  if (DEPTH < want) {
    place_new()
    print line
    return
  }

  if (DEPTH == want) {
    parent_empty = 0
  }

  if (DEPTH != want || KEY != SEGMENT[at_segment]) {
    print line
    return
  }

  if (at_segment == SEGMENTS) {
    replace(KEY)
    return
  }

  descend(line)
}

# Puts the value in place of the matched member and marks its old lines to
# be dropped.
function replace(key) {
  nest(key, want)
  done = 1
  skipping = 1
  at = want
}

# Keeps the matched line and moves the walk one level down; a scalar cannot
# be gone through.
function descend(line) {
  if (LEAF || TYPE == "null") {
    refuse("not a collection at " KEY)
  }

  print line
  want++
  at_segment++
  parent_kind = TYPE
  parent_empty = 1
}

# Adds the value as a new member at the current depth, creating the parents
# the remaining segments name.
function place_new(__depth) {
  __depth = want

  while (1) {
    key_ok(SEGMENT[at_segment])

    if (at_segment == SEGMENTS) {
      nest(SEGMENT[at_segment], __depth)
      done = 1
      return
    }

    place_parent(SEGMENT[at_segment], __depth, SEGMENT[at_segment + 1])
    __depth++
    at_segment++
  }
}

# Creates a missing parent: a list when the segment after it is an index, a
# map otherwise.
function place_parent(key, depth, next_segment) {
  if (is_name(next_segment)) {
    print depth "." key ":map"
    parent_kind = "map"
  } else {
    print depth "." key ":list"
    parent_kind = "list"
  }

  parent_empty = 1
}

# Refuses a new key that does not fit its parent: a name under a list, an
# index under a map, or an index other than 0 in a list with nothing in it
# yet.
function key_ok(key) {
  if (parent_kind == "map" && !is_name(key)) {
    refuse("a map takes a name, not the index " key)
  }

  if (parent_kind == "list" && is_name(key)) {
    refuse("a list takes an index, not the name " key)
  }

  if (parent_kind == "list" && !(parent_empty && key == "0")) {
    refuse("no element " key " to set; push appends to a list")
  }
}

# Prints the value under key at depth: a scalar or an empty collection as
# one line, a collection as its type line and its members one level deeper.
function nest(key, depth, __i) {
  parse(VALUE_LINE[1])

  if (KEY == "") {
    print depth "." key ":" substr(VALUE_LINE[1], 4)
    return
  }

  if (is_name(KEY)) {
    print depth "." key ":map"
  } else {
    print depth "." key ":list"
  }

  for (__i = 1; __i <= VALUES; __i++) {
    print redepth(VALUE_LINE[__i], depth + 1)
  }
}

BEGIN {
  load_segments()
  read_value()
  want = 0
  at_segment = 1
  done = 0
  skipping = 0
  parent_kind = ENVIRON["SILT_KIND"]
  parent_empty = 1
}

is_keyless($0) {
  next
}

{
  parse($0)

  if (skipping) {
    if (DEPTH > at) {
      next
    }
    skipping = 0
  }

  if (!done) {
    match_line($0)
    next
  }

  print
}

END {
  if (!done) {
    place_new()
  }
}
