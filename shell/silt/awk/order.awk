# Canonical order, RFC 8785's, for the lines of a SILT document, loaded by
# every program that prints a document in that order: silt__canon and the
# translators into SILT. A program hands take() each line as it has it, then
# prints them with print_ordered() once it has them all, since a map's order
# is not known until its last member. Each line gets one sort key made of
# its ancestors' keys and its own, a map's keys compared by their UTF-16
# code units, and one sort of all the lines by that key is the document.
# It holds functions alone; a program's BEGIN calls order_begin() first.

# Keeps a line, and gives it its sort key: the key of the line it sits
# under, then a slash, then its own. A named member's own key is its
# decoded key as UTF-16 code units; a list element's is its index, padded
# so numbers order as numbers. The slash orders before every key character,
# so a line sorts right after its parent and its siblings sort by key.
function take(line, __depth, __own) {
  LINES++
  LINE[LINES] = line
  ORDER[LINES] = LINES

  parse(line)
  __depth = DEPTH
  if (is_name(KEY)) {
    __own = "n" utf16_key(unwrap(KEY))
  } else {
    __own = sprintf("i%012d", KEY)
  }

  SORT_KEY[LINES] = (__depth > 0 ? KEY_AT[__depth - 1] : "") "/" __own
  KEY_AT[__depth] = SORT_KEY[LINES]
}

# The text as a string of its UTF-16 code units, each as four hex digits, so
# a plain string comparison orders two keys as RFC 8785 does.
function utf16_key(text, __key, __i, __code) {
  __key = ""
  __i = 1

  while (__i <= length(text)) {
    __code = code_point(text, __i)
    if (__code >= 65536) {
      __key = __key sprintf("%04x%04x", 55296 + int((__code - 65536) / 1024), 56320 + (__code - 65536) % 1024)
    } else {
      __key = __key sprintf("%04x", __code)
    }
    __i = __i + CODE_WIDTH
  }

  return __key
}

# The code point of the UTF-8 sequence starting at <at> in the text, with
# CODE_WIDTH set to how many bytes it took.
function code_point(text, at, __lead) {
  __lead = ORD[substr(text, at, 1)]
  CODE_WIDTH = 1

  if (__lead < 128) {
    return __lead
  }
  if (__lead < 224) {
    CODE_WIDTH = 2
    return (__lead - 192) * 64 + tail_bits(text, at + 1)
  }
  if (__lead < 240) {
    CODE_WIDTH = 3
    return (__lead - 224) * 4096 + tail_bits(text, at + 1) * 64 + tail_bits(text, at + 2)
  }

  CODE_WIDTH = 4
  return (__lead - 240) * 262144 + tail_bits(text, at + 1) * 4096 + tail_bits(text, at + 2) * 64 + tail_bits(text, at + 3)
}

# The six payload bits of a UTF-8 continuation byte.
function tail_bits(text, at) {
  return ORD[substr(text, at, 1)] - 128
}

# Orders ORDER[1..LINES] by SORT_KEY, a bottom-up merge sort: runs of one,
# then two, then four, merged pairwise until one run is left. Stable, so a
# key a map holds twice keeps the two in their order.
function sort_lines(__width, __left) {
  for (__width = 1; __width < LINES; __width = __width * 2) {
    for (__left = 1; __left <= LINES; __left = __left + 2 * __width) {
      merge_runs(__left, least(__left + __width, LINES + 1), least(__left + 2 * __width, LINES + 1))
    }
    copy_back()
  }
}

# Merges the run ORDER[left..middle-1] with ORDER[middle..end-1] into
# MERGED[left..end-1], taking the left on a tie.
function merge_runs(left, middle, end, __i, __j, __k) {
  __i = left
  __j = middle

  for (__k = left; __k < end; __k++) {
    if (__i < middle && (__j >= end || SORT_KEY[ORDER[__i]] <= SORT_KEY[ORDER[__j]])) {
      MERGED[__k] = ORDER[__i]
      __i++
    } else {
      MERGED[__k] = ORDER[__j]
      __j++
    }
  }
}

# Makes the merged runs the order for the next pass.
function copy_back(__k) {
  for (__k = 1; __k <= LINES; __k++) {
    ORDER[__k] = MERGED[__k]
  }
}

# The smaller of two numbers.
function least(a, b) {
  return a < b ? a : b
}

# Readies the byte table the code points are read through, and the count of
# lines kept.
function order_begin(__i) {
  LINES = 0
  for (__i = 0; __i < 256; __i++) {
    ORD[sprintf("%c", __i)] = __i
  }
}

# Prints every line kept, in canonical order.
function print_ordered(__i) {
  sort_lines()
  for (__i = 1; __i <= LINES; __i++) {
    print LINE[ORDER[__i]]
  }
}
