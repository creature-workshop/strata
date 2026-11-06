# The elements of the list on stdin whose value is in no element of the
# list sent ahead of it, in their order and renumbered: silt__difference.
# Two elements are the same when their canonical texts are, the way
# silt__equals says. Loaded after lines.awk, order.awk and elements.awk.
#
#   0.0:int=1        second  0.0:int=2   ->  0.0:int=1
#   0.1:int=2

# Holds the canonical text of every element of document 2 in HELD.
function hold_second(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] == 2) {
      HELD[identity_of(__i)] = 1
    }
  }
}

# Prints each element of document 1 whose value document 2 does not hold.
function print_difference(__i, __count) {
  __count = 0

  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] != 1 || (identity_of(__i) in HELD)) {
      continue
    }

    print_element(__i, __count)
    __count++
  }

  if (__count == 0) {
    print "0.:list"
  }
}

# Keeps every line for END.
function main() {
  keep($0)
}

BEGIN {
  elements_begin()
  read_ahead()
}

END {
  keep_second()
  close_members()
  hold_second()
  print_difference()
}

{ main() }
