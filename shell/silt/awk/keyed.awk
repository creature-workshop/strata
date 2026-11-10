# The order of a list's elements by the values at paths inside them, for
# the programs that sort, group and pick by it: silt__sort_by,
# silt__group_by, silt__min and silt__max. It holds functions alone. A
# program's BEGIN names its verb in VERB and calls load_paths(). Its END
# calls read_keys() once elements.awk has every element, and then
# compare_elements() or sort_elements(). Loaded after lines.awk, order.awk
# and elements.awk.
#
# Two values are ordered by kind first: nothing and a null, then false,
# then true, then a number, then a text. Two numbers are ordered by size and
# two texts byte by byte. A str is read as the text it spells, and a time as
# it is written. A map or a list at a path is refused.
#
#   PATHS                 how many paths the verb was given, at least 1
#   SEGMENTS_OF[p]        how many segments path p has; 0 is the element
#   SEGMENT_AT[p, n]      segment n of path p, as a line writes a key
#   RANK[i, p]            the kind of the value at path p in element i
#   NUMBER[i, p]          that value, when it is a number
#   TEXT[i, p]            that value, when it is a text
#   SORTED[1..MEMBERS]    the elements in order, after sort_elements()

# Loads the paths the shell hands over in SILT_SEGMENTS: one segment on
# each line, and a line that holds the record separator alone between two
# paths. A verb given no path gets one path with no segment, which is the
# element itself.
function load_paths(__lines, __count, __i) {
  PATHS = 1
  SEGMENTS_OF[1] = 0

  __count = split(ENVIRON["SILT_SEGMENTS"], __lines, "\n")
  for (__i = 1; __i <= __count; __i++) {
    load_path_line(__lines[__i])
  }
}

# Takes one line of SILT_SEGMENTS: the separator opens the next path, an
# empty line is the place of a path with no segment, and any other line is
# the next segment of the path being read.
function load_path_line(line) {
  if (line == "") {
    return
  }

  if (ends_ahead(line)) {
    PATHS++
    SEGMENTS_OF[PATHS] = 0
    return
  }

  SEGMENTS_OF[PATHS]++
  SEGMENT_AT[PATHS, SEGMENTS_OF[PATHS]] = line
}

# Reads the key of every element at every path.
function read_keys(__i, __p) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    for (__p = 1; __p <= PATHS; __p++) {
      read_key(__i, __p)
    }
  }
}

# Reads the value at path p in element i into RANK, NUMBER and TEXT. An
# element that holds nothing at the path has the rank of a null. Refuses a
# map or a list there.
function read_key(i, p, __at) {
  __at = line_at_path(i, p)
  if (__at == 0) {
    RANK[i, p] = 0
    return
  }

  parse(INPUT[__at])
  if (TYPE == "map" || TYPE == "list") {
    refuse(VERB " orders by scalars, not by a " TYPE ", in the element at index " KEY_OF[i])
  }

  RANK[i, p] = rank_of_parsed()
  if (RANK[i, p] == 3) {
    NUMBER[i, p] = VALUE + 0
  }
  if (RANK[i, p] == 4) {
    TEXT[i, p] = (TYPE == "str") ? unwrap(VALUE) : VALUE
  }
}

# The rank of the kind of the line last parsed: 0 for a null, 1 for false,
# 2 for true, 3 for a number and 4 for a text.
function rank_of_parsed() {
  if (TYPE == "null") {
    return 0
  }
  if (TYPE == "bool") {
    return (VALUE == "true") ? 2 : 1
  }
  if (TYPE == "int" || TYPE == "float") {
    return 3
  }

  return 4
}

# The index in INPUT of the line that holds the value at path p inside
# element i, or 0 when the element holds nothing there. A path with no
# segment is the element's own line.
function line_at_path(i, p, __at, __want, __segment) {
  if (SEGMENTS_OF[p] == 0) {
    return FIRST[i]
  }

  __want = 1
  __segment = 1
  for (__at = FIRST[i] + 1; __at <= LAST[i]; __at++) {
    parse(INPUT[__at])

    if (DEPTH < __want) {
      return 0
    }
    if (DEPTH != __want || KEY != SEGMENT_AT[p, __segment]) {
      continue
    }
    if (__segment == SEGMENTS_OF[p]) {
      return __at
    }

    __segment++
    __want++
  }

  return 0
}

# Compares elements a and b by their keys, the first path first: -1 when a
# orders before b, 1 when it orders after, and 0 when every key ties.
function compare_elements(a, b, __p, __order) {
  for (__p = 1; __p <= PATHS; __p++) {
    __order = compare_keys(a, b, __p)
    if (__order != 0) {
      return __order
    }
  }

  return 0
}

# Compares the keys of elements a and b at path p: -1, 0 or 1.
function compare_keys(a, b, p) {
  if (RANK[a, p] != RANK[b, p]) {
    return (RANK[a, p] < RANK[b, p]) ? -1 : 1
  }
  if (RANK[a, p] == 3) {
    return order_of_numbers(NUMBER[a, p], NUMBER[b, p])
  }
  if (RANK[a, p] == 4) {
    return order_of_texts(TEXT[a, p], TEXT[b, p])
  }

  return 0
}

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
