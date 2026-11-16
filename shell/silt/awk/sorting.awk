# The comparisons and the merge sort that every program which orders the
# elements of a list uses. This file contains functions only. The program
# that loads it defines compare_elements(a, b), which returns -1, 0 or 1
# for two elements that elements.awk read. Loaded after lines.awk,
# order.awk and elements.awk.
#
#   SORTED[1..MEMBERS]    the elements in order, after sort_elements()

# Compares two numbers: -1, 0 or 1.
function order_of_numbers(a, b) {
  if (a == b) {
    return 0
  }

  return (a < b) ? -1 : 1
}

# Compares two texts byte by byte: -1, 0 or 1. The empty string joined to
# each makes awk compare them as texts even when both read as numbers.
function order_of_texts(a, b) {
  if ((a "") == (b "")) {
    return 0
  }

  return ((a "") < (b "")) ? -1 : 1
}

# Puts the elements in order in SORTED[1..MEMBERS], a bottom-up merge sort:
# runs of one, then two, then four, merged pairwise until one run is left.
# Elements whose keys all tie keep the order the list holds them in.
function sort_elements(__width, __left, __i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    SORTED[__i] = __i
  }

  for (__width = 1; __width < MEMBERS; __width = __width * 2) {
    for (__left = 1; __left <= MEMBERS; __left = __left + 2 * __width) {
      merge_sorted(__left, least(__left + __width, MEMBERS + 1), least(__left + 2 * __width, MEMBERS + 1))
    }
    for (__i = 1; __i <= MEMBERS; __i++) {
      SORTED[__i] = MERGING[__i]
    }
  }
}

# Merges the run SORTED[left..middle-1] with SORTED[middle..end-1] into
# MERGING[left..end-1], taking the left on a tie.
function merge_sorted(left, middle, end, __i, __j, __k) {
  __i = left
  __j = middle

  for (__k = left; __k < end; __k++) {
    if (__i < middle && (__j >= end || compare_elements(SORTED[__i], SORTED[__j]) <= 0)) {
      MERGING[__k] = SORTED[__i]
      __i++
    } else {
      MERGING[__k] = SORTED[__j]
      __j++
    }
  }
}
