# The element of a list that orders first, as a document of its own:
# silt__min. Of several that tie it is the first, and the empty list
# answers nothing. Loaded after lines.awk, order.awk, elements.awk and
# keyed.awk.
#
#   0.0:int=3
#   0.1:int=1   ->  0.:int=1

# Keeps every line for END.
function main() {
  keep($0)
}

# The element that orders before every other, the first of several that
# tie.
function least_element(__i, __least) {
  __least = 1

  for (__i = 2; __i <= MEMBERS; __i++) {
    if (compare_elements(__i, __least) < 0) {
      __least = __i
    }
  }

  return __least
}

BEGIN {
  VERB = "min"
  elements_begin()
  load_paths()
}

END {
  if (REFUSED) {
    exit 1
  }

  close_members()
  read_keys()

  if (MEMBERS > 0) {
    print_value(least_element())
  }
}

{ main() }
