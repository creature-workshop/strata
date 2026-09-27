# The members of a map or a list, one block each for silt__each past the
# threshold: the key as text on one line, the member's value as a document,
# then a line holding the record separator alone.
BEGIN { open = 0; RS_LINE = sprintf("%c", 30) }

substr($0, 1, 3) == "0.:" { exit }

substr($0, 1, 2) == "0." {
  close_member()
  parse($0)
  if (substr(KEY, 1, 1) == "\"") { print unwrap(KEY) } else { print KEY }
  if (LEAF) { root = "0.:" TYPE "=" VALUE } else { root = "0.:" TYPE }
  open = 1
  next
}

{
  if (root != "") { root = "" }
  print redepth($0, -1)
}

END { close_member() }

# Ends the member open, if one is: its placeholder root when nothing deeper
# replaced it, then the separator line.
function close_member() {
  if (!open) { return }
  if (root != "") { print root; root = "" }
  print RS_LINE
  open = 0
}
