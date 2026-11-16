# Prints the list on stdin with its elements in the order of their values,
# renumbered from 0: silt__sort. Elements that are the same value keep the
# order the list has them in. Loaded after lines.awk, order.awk,
# elements.awk and sorting.awk.
#
# Values are ordered by kind first: null, then false, then true, then
# numbers, then texts, then lists, then maps. Two numbers are ordered by
# size, and two texts byte by byte, with a str read as the text it stands
# for. Two lists are compared element by element, and the shorter one
# comes first when one is the start of the other. Two maps are compared by
# their sorted keys first, and then by their values in that order.
#
#   0.0:str="b"
#   0.1:list
#   1.0:int=1
#   0.2:int=2
#   0.3:null     ->  0.0:null
#                    0.1:int=2
#                    0.2:str="b"
#                    0.3:list
#                    1.0:int=1
#
#   DEPTH_AT[n], KEY_AT[n], TYPE_AT[n], VALUE_AT[n]  the parts of INPUT[n]

function main(line) {
  keep(line)
}

# Reads the parts of every line that was kept.
function read_lines(__n) {
  for (__n = 1; __n <= INPUTS; __n++) {
    parse(INPUT[__n])
    DEPTH_AT[__n] = DEPTH
    KEY_AT[__n] = KEY
    TYPE_AT[__n] = TYPE
    VALUE_AT[__n] = VALUE
  }
}

# Compares elements a and b by their values: -1, 0 or 1.
function compare_elements(a, b) {
  return compare_values(FIRST[a], FIRST[b])
}

# Compares the values at lines a and b: -1, 0 or 1.
function compare_values(a, b, __rank) {
  if (rank_at(a) != rank_at(b)) {
    return (rank_at(a) < rank_at(b)) ? -1 : 1
  }

  __rank = rank_at(a)
  if (__rank == 3) {
    return order_of_numbers(VALUE_AT[a] + 0, VALUE_AT[b] + 0)
  }
  if (__rank == 4) {
    return order_of_texts(text_at(a), text_at(b))
  }
  if (__rank == 5) {
    return compare_lists(a, b)
  }
  if (__rank == 6) {
    return compare_maps(a, b)
  }

  return 0
}

# The rank of the kind of the value at line n: 0 for a null, 1 for false,
# 2 for true, 3 for a number, 4 for a text, 5 for a list and 6 for a map.
function rank_at(n) {
  if (TYPE_AT[n] == "null") {
    return 0
  }
  if (TYPE_AT[n] == "bool") {
    return (VALUE_AT[n] == "true") ? 2 : 1
  }
  if (TYPE_AT[n] == "int" || TYPE_AT[n] == "float") {
    return 3
  }
  if (TYPE_AT[n] == "list") {
    return 5
  }
  if (TYPE_AT[n] == "map") {
    return 6
  }

  return 4
}

# The text of the value at line n: what a str stands for, and any other
# text as its line writes it.
function text_at(n) {
  return (TYPE_AT[n] == "str") ? unwrap(VALUE_AT[n]) : VALUE_AT[n]
}

# Fills out[1..count] with the lines of the children of the value at line
# n, in their order, and returns count.
function children_of(n, out, __at, __count) {
  __count = 0
  for (__at = n + 1; __at <= INPUTS && DEPTH_AT[__at] > DEPTH_AT[n]; __at++) {
    if (DEPTH_AT[__at] == DEPTH_AT[n] + 1) {
      out[++__count] = __at
    }
  }

  return __count
}

# Compares the lists at lines a and b element by element: -1, 0 or 1. When
# one list is the start of the other, the shorter one comes first.
function compare_lists(a, b, __of_a, __of_b, __in_a, __in_b, __k, __order) {
  __in_a = children_of(a, __of_a)
  __in_b = children_of(b, __of_b)

  for (__k = 1; __k <= __in_a && __k <= __in_b; __k++) {
    __order = compare_values(__of_a[__k], __of_b[__k])
    if (__order != 0) {
      return __order
    }
  }

  return order_of_numbers(__in_a, __in_b)
}

# Compares the maps at lines a and b: -1, 0 or 1. The sorted keys are
# compared first, and the values, in the order of the keys, only when both
# maps have the same keys.
function compare_maps(a, b, __of_a, __of_b, __in_a, __in_b, __order) {
  __in_a = children_of(a, __of_a)
  __in_b = children_of(b, __of_b)
  sort_by_key(__of_a, __in_a)
  sort_by_key(__of_b, __in_b)

  __order = compare_keys(__of_a, __in_a, __of_b, __in_b)
  if (__order != 0) {
    return __order
  }

  return compare_members(__of_a, __of_b, __in_a)
}

# Compares the keys of two maps whose members are in key order: -1, 0 or
# 1. When one map's keys are the start of the other's, the map with fewer
# keys comes first.
function compare_keys(of_a, in_a, of_b, in_b, __k, __order) {
  for (__k = 1; __k <= in_a && __k <= in_b; __k++) {
    __order = order_of_texts(unwrap(KEY_AT[of_a[__k]]), unwrap(KEY_AT[of_b[__k]]))
    if (__order != 0) {
      return __order
    }
  }

  return order_of_numbers(in_a, in_b)
}

# Compares the values of two maps that have the same keys, in the order
# of the keys: -1, 0 or 1.
function compare_members(of_a, of_b, count, __k, __order) {
  for (__k = 1; __k <= count; __k++) {
    __order = compare_values(of_a[__k], of_b[__k])
    if (__order != 0) {
      return __order
    }
  }

  return 0
}

# Puts the member lines in lines[1..count] in the order of their keys, in
# place. This is an insertion sort, which is enough for the members of one
# map.
function sort_by_key(lines, count, __i, __j, __moved) {
  for (__i = 2; __i <= count; __i++) {
    __moved = lines[__i]
    for (__j = __i - 1; __j >= 1 && order_of_texts(unwrap(KEY_AT[lines[__j]]), unwrap(KEY_AT[__moved])) > 0; __j--) {
      lines[__j + 1] = lines[__j]
    }
    lines[__j + 1] = __moved
  }
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
  elements_begin()
}

END {
  if (REFUSED) {
    exit 1
  }

  close_members()
  read_lines()
  sort_elements()
  print_sorted()
}

{ main($0) }
