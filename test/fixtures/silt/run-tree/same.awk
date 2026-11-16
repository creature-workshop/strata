# Prints one line of plain text for each member of the map "left": its
# name, and whether the map "right" has the same value under that name.
# It calls same_value(), which tree_equal.awk defines.

function main(line) {
  tree_line(line)
}

# Prints the name of every member of left with "same" or "differs".
function print_comparison(left, right, __member) {
  for (__member = NODE_FIRST[left]; __member != 0; __member = NODE_NEXT[__member]) {
    print name_of(__member) ": " (same_value(__member, member(right, name_of(__member))) ? "same" : "differs")
  }
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  print_comparison(member(ROOT, "left"), member(ROOT, "right"))
}

{ main($0) }
