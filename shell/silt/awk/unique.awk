# The list with every element that is the same value as an earlier one
# dropped, the rest in their order and renumbered: silt__unique. Two
# elements are the same when their canonical texts are, the way
# silt__equals says. Loaded after lines.awk, order.awk and elements.awk.
#
#   0.0:int=1
#   0.1:int=2
#   0.2:int=1   ->  0.0:int=1
#                   0.1:int=2

# Prints each element the first time its value is seen.
function print_unique(__i, __identity, __count) {
  __count = 0

  for (__i = 1; __i <= MEMBERS; __i++) {
    __identity = identity_of(__i)
    if (__identity in SEEN) {
      continue
    }

    SEEN[__identity] = 1
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
  close_members()
  print_unique()
}

{ main() }
