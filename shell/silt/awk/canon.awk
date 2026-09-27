# The document with every map's members in canonical order: silt__canon.
# Canonical order is RFC 8785's, the keys compared by their UTF-16 code
# units, so a map built in call order and the same map built in another
# come out the same bytes. Lists keep their order, and every line keeps its
# text. The whole document is read first, since a member's children sit
# below it and a map's order is not known until its last member.

# Reads a line into LINE and its depth into AT.
function take(line) {
  LINES++
  LINE[LINES] = line
  AT[LINES] = substr(line, 1, index(line, ".") - 1) + 0
}

# Prints the lines under the parent at index <of>, whose depth is <depth>:
# the parent's direct children in canonical order when they are named, in
# their own order otherwise, each followed by what sits under it. The
# children ride in an array of this call's own, since the call recurses.
function print_children(of, depth, __child, __count, __i, __at) {
  __count = children(of, depth, __child)

  if (__count > 0 && is_name(key_of(__child[1]))) {
    sort_children(__child, __count)
  }

  for (__i = 1; __i <= __count; __i++) {
    __at = __child[__i]
    print LINE[__at]
    print_children(__at, depth + 1)
  }
}

# Fills <into>[1..count] with the indices of the lines directly under the
# line at <of>, whose depth is <depth>: the lines one deeper, up to the
# first line no deeper than the parent. Returns the count. The virtual root
# is index 0 at depth -1.
function children(of, depth, into, __count, __i) {
  __count = 0

  for (__i = of + 1; __i <= LINES; __i++) {
    if (AT[__i] <= depth) {
      break
    }
    if (AT[__i] == depth + 1) {
      into[++__count] = __i
    }
  }

  return __count
}

# Orders <child>[1..count] by their keys' UTF-16 code units, an insertion
# sort over the sort keys, since a map's member count is small.
function sort_children(child, count, __i, __j, __at, __key) {
  for (__i = 1; __i <= count; __i++) {
    SORT_KEY[child[__i]] = utf16_key(unwrap(key_of(child[__i])))
  }

  for (__i = 2; __i <= count; __i++) {
    __at = child[__i]
    __key = SORT_KEY[__at]
    __j = __i - 1
    while (__j >= 1 && SORT_KEY[child[__j]] > __key) {
      child[__j + 1] = child[__j]
      __j--
    }
    child[__j + 1] = __at
  }
}

# The key of the line at <at>, as the line writes it.
function key_of(at) {
  parse(LINE[at])

  return KEY
}

# The text as a string of its UTF-16 code units, each as four hex digits, so
# a plain string comparison orders two keys as RFC 8785 does.
function utf16_key(text, __key, __i, __code, __width) {
  __key = ""
  __i = 1

  while (__i <= length(text)) {
    __code = code_point(text, __i)
    __width = CODE_WIDTH
    if (__code >= 65536) {
      __key = __key sprintf("%04x%04x", 55296 + int((__code - 65536) / 1024), 56320 + (__code - 65536) % 1024)
    } else {
      __key = __key sprintf("%04x", __code)
    }
    __i = __i + __width
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

# Keeps every line for END, where the order is known.
function main() {
  take($0)
}

BEGIN {
  LINES = 0
  for (ORD_I = 0; ORD_I < 256; ORD_I++) {
    ORD[sprintf("%c", ORD_I)] = ORD_I
  }
}

END {
  print_children(0, -1)
}

{ main() }
