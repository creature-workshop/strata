# The members of a map or a list, one block each for silt__each past the
# threshold: the key as text on one line, the member's value as a document,
# then a line holding the record separator alone. The empty collection's
# one keyless line has no member to write.

# Opens a member from its parsed line: delivers the one open, prints the
# key as text, and holds the value's root until a deeper line replaces it.
function open_member() {
  close_member()

  if (is_name(KEY)) {
    print unwrap(KEY)
  } else {
    print KEY
  }

  root = LEAF ? "0.:" TYPE "=" VALUE : "0.:" TYPE
  open = 1
}

# Adds a deeper line to the member open, moved up so the member's own
# members sit at depth 0; the first one replaces the placeholder root.
function extend_member(line) {
  root = ""
  print redepth(line, -1)
}

# Ends the member open, if one is: its placeholder root when nothing deeper
# replaced it, then the separator line.
function close_member() {
  if (!open) {
    return
  }

  if (root != "") {
    print root
    root = ""
  }

  print RS_LINE
  open = 0
}

# One line: the empty collection's keyless line is nothing, a depth-0 line
# opens a member, a deeper one extends the member open.
function main() {
  if (is_keyless($0)) {
    return
  }

  parse($0)

  if (DEPTH == 0) {
    open_member()
  } else {
    extend_member($0)
  }
}

BEGIN {
  open = 0
  root = ""
  RS_LINE = sprintf("%c", 30)
}

END {
  close_member()
}

{ main() }
