# The value at the path in SILT_SEGMENTS, as a document of its own:
# silt__get past the threshold. The run is in one of three states: seeking
# the segment wanted, collecting the value's members once its line is found,
# and finished, when the lines left are read and skipped. Nothing is printed
# for a path no member holds; the value's root is printed from END.

# Seeking: matches a parsed line against the segment wanted at the depth
# wanted. A shallower line finishes the run without a value, a line that is
# not the segment is skipped, and the segment itself is the value when the
# path ends there, or sends the search one level down.
function match_segment() {
  if (DEPTH < want) {
    state = "finished"
    return
  }

  if (DEPTH != want || KEY != SEGMENT[at_segment]) {
    return
  }

  if (at_segment == SEGMENTS) {
    at = DEPTH
    root = LEAF ? "0.:" TYPE "=" VALUE : "0.:" TYPE
    state = "collecting"
    return
  }

  at_segment++
  want++
}

# Collecting: a line no deeper than the value finishes the run, a deeper one
# is a member moved up so the value's own members sit at depth 0, and the
# first member replaces the placeholder root.
function collect_member(line) {
  if (DEPTH <= at) {
    state = "finished"
    return
  }

  if (root != "") {
    root = ""
  }

  print redepth(line, -at - 1)
}

# One line in the run's state: finished reads and skips, collecting takes
# the line as a member of the value, seeking matches it against the segment
# wanted.
function main() {
  if (state == "finished") {
    return
  }

  parse($0)

  if (state == "collecting") {
    collect_member($0)
  } else {
    match_segment()
  }
}

BEGIN {
  load_segments()
  want = 0
  at_segment = 1
  root = ""
  state = "seeking"
}

END {
  if (root != "") {
    print root
  }
}

{ main() }
