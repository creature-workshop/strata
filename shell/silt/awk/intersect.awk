# The elements of the list on stdin whose value some element of the list in
# SILT_SPILL also holds, in their order and renumbered, an element the
# first list holds twice kept twice: silt__intersect. Two elements are the
# same when their canonical texts are, the way silt__equals says. Loaded
# after lines.awk, order.awk and elements.awk.
#
#   0.0:int=1        spill  0.0:int=2   ->  0.0:int=2
#   0.1:int=2

# Holds the canonical text of every element of document 2 in HELD.
function hold_second(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] == 2) {
      HELD[identity_of(__i)] = 1
    }
  }
}

# Prints each element of document 1 whose value document 2 holds too.
function print_intersection(__i, __count) {
  __count = 0

  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] != 1 || !(identity_of(__i) in HELD)) {
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
}

END {
  keep_spill()
  close_members()
  hold_second()
  print_intersection()
}

{ main() }
