# The element of a list that orders last, as a document of its own:
# silt__max. Of several that tie it is the last, and the empty list answers
# nothing. Loaded after lines.awk, order.awk, elements.awk and keyed.awk.
#
#   0.0:int=3
#   0.1:int=1   ->  0.:int=3

# Keeps every line for END.
function main() {
  keep($0)
}

# The element that orders after every other, the last of several that tie.
function greatest_element(__i, __greatest) {
  __greatest = 1

  for (__i = 2; __i <= MEMBERS; __i++) {
    if (compare_elements(__i, __greatest) >= 0) {
      __greatest = __i
    }
  }

  return __greatest
}

BEGIN {
  VERB = "max"
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
    print_value(greatest_element())
  }
}

{ main() }
