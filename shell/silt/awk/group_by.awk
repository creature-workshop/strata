# The list's elements gathered into lists of the ones whose keys are the
# same, the groups in the order of their keys: silt__group_by. Inside a
# group the elements keep their order. Loaded after lines.awk, order.awk,
# elements.awk and keyed.awk.
#
#   0.0:str="b"
#   0.1:str="a"
#   0.2:str="b"   ->  0.0:list
#                     1.0:str="a"
#                     0.1:list
#                     1.0:str="b"
#                     1.1:str="b"

# Keeps every line for END.
function main() {
  keep($0)
}

# Prints the groups: the elements in order, a new group opened wherever an
# element's keys differ from those of the element before it.
function print_groups(__i, __group, __position) {
  __group = -1

  for (__i = 1; __i <= MEMBERS; __i++) {
    if (__i == 1 || compare_elements(SORTED[__i - 1], SORTED[__i]) != 0) {
      __group++
      __position = 0
      print "0." __group ":list"
    }

    print_grouped(SORTED[__i], __position)
    __position++
  }

  if (MEMBERS == 0) {
    print "0.:list"
  }
}

# Prints element i as the element at <position> of a group: its own line
# at depth 1 under that index, and its deeper lines one level down.
function print_grouped(i, position, __at) {
  print "1." position substr(INPUT[FIRST[i]], index(INPUT[FIRST[i]], ":"))

  for (__at = FIRST[i] + 1; __at <= LAST[i]; __at++) {
    print redepth(INPUT[__at], 1)
  }
}

BEGIN {
  VERB = "group_by"
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
  print_groups()
}

{ main() }
