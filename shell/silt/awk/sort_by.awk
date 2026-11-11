# The list with its elements ordered by the values at paths inside them:
# silt__sort_by. Elements whose keys all tie keep their order. Loaded after
# lines.awk, order.awk, elements.awk and keyed.awk.
#
#   0.0:map
#   1."at":int=2
#   0.1:map
#   1."at":int=1   ->  0.0:map
#                      1."at":int=1
#                      0.1:map
#                      1."at":int=2

# Keeps every line for END.
function main() {
  keep($0)
}

# Prints the elements in order, renumbered from 0, or the empty list.
function print_sorted(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    print_element(SORTED[__i], __i - 1)
  }

  if (MEMBERS == 0) {
    print "0.:list"
  }
}

BEGIN {
  VERB = "sort_by"
  elements_begin()
  load_paths()
}

END {
  if (REFUSED) {
    exit 1
  }

  close_members()
  read_keys()
  sort_elements()
  print_sorted()
}

{ main() }
