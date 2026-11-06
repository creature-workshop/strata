# The map on stdin with the map sent ahead of it laid over it, one level
# deep: silt__merge. A key both hold takes the second map's value, in the
# first map's place; a key only the second holds is added after the first's
# members, in the second's order. Two keys are the same when their decoded
# texts are. Loaded after lines.awk, order.awk and elements.awk.
#
#   0."a":int=1      second  0."b":int=3   ->  0."a":int=1
#   0."b":int=2              0."c":int=4       0."b":int=3
#                                              0."c":int=4

# Notes which member of document 2 holds each key, by its decoded text.
function index_second(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] == 2) {
      SECOND[unwrap(KEY_OF[__i])] = __i
    }
  }
}

# Prints the first map's members, each replaced by the second map's member
# under the same key when there is one, and counts what was printed.
function print_first(__i, __key) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] != 1) {
      continue
    }

    __key = unwrap(KEY_OF[__i])
    if (__key in SECOND) {
      print_member(SECOND[__key])
      TAKEN[__key] = 1
    } else {
      print_member(__i)
    }
    PRINTED++
  }
}

# Prints the second map's members the first did not hold, in their order.
function print_second_only(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    if (DOC_OF[__i] != 2 || (unwrap(KEY_OF[__i]) in TAKEN)) {
      continue
    }

    print_member(__i)
    PRINTED++
  }
}

# Prints the merged map, or the empty map's line when both were empty.
function print_merge() {
  PRINTED = 0
  index_second()
  print_first()
  print_second_only()

  if (PRINTED == 0) {
    print "0.:map"
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
  print_merge()
}

{ main() }
