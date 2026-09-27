# The value at the path in SILT_SEGMENTS, as a document of its own:
# silt__get past the threshold. Nothing is printed for a path no member
# holds. Once the answer is known the remaining lines are read and skipped,
# and the answer's root is printed from END.

# Matches a parsed line against the segment being looked for at the depth
# wanted: a shallower line ends the search, a line that is not the segment is
# skipped, and the segment itself is the value when the path ends there, or
# sends the search one level down.
function match_segment() {
  if (DEPTH < want) {
    decided = 1
    return
  }

  if (DEPTH != want || KEY != SEGMENT[at_segment]) {
    return
  }

  if (at_segment == SEGMENTS) {
    found = 1
    at = DEPTH
    root = LEAF ? "0.:" TYPE "=" VALUE : "0.:" TYPE
    return
  }

  at_segment++
  want++
}

# Collects a parsed line after the value was found: a line no deeper than
# the value ends the collection, a deeper one is a member moved up so the
# value's own members sit at depth 0, and the first member replaces the
# placeholder root.
function collect_member(line) {
  if (DEPTH <= at) {
    decided = 1
    return
  }

  if (root != "") {
    root = ""
  }

  print redepth(line, -at - 1)
}

BEGIN {
  load_segments()
  want = 0
  at_segment = 1
  found = 0
  decided = 0
  root = ""
}

decided {
  next
}

{
  parse($0)

  if (found) {
    collect_member($0)
  } else {
    match_segment()
  }
}

END {
  if (root != "") {
    print root
  }
}
