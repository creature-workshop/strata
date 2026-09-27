# The line library every SILT awk program loads first, with -f ahead of the
# program: a line into its parts, a line moved to another depth, the path
# segments the shell hands over, a JSON string literal decoded, and the
# refusal that ends a run the way the shell's does. It holds functions alone,
# so no rule of it runs on any line.

# Reads a line into DEPTH, KEY, TYPE, VALUE and LEAF, the way the shell's
# parse does: the key a quoted literal under a map, bare digits under a list,
# empty on a keyless line; LEAF 1 when the line carries a value. Refuses a
# line with no depth, and a quoted key that never closes.
function parse(line, __rest, __head) {
  if (index(line, ".") == 0) {
    refuse("not a SILT line: " line)
  }

  DEPTH = substr(line, 1, index(line, ".") - 1) + 0
  __rest = substr(line, index(line, ".") + 1)

  if (substr(__rest, 1, 1) == "\"") {
    __head = quoted_key(__rest)
    if (__head == __rest) {
      refuse("a quoted literal never closes: " __rest)
    }
    KEY = __head
    __rest = substr(__rest, length(__head) + 2)
  } else {
    KEY = substr(__rest, 1, index(__rest, ":") - 1)
    __rest = substr(__rest, index(__rest, ":") + 1)
  }

  if (index(__rest, "=") > 0) {
    TYPE = substr(__rest, 1, index(__rest, "=") - 1)
    VALUE = substr(__rest, index(__rest, "=") + 1)
    LEAF = 1
  } else {
    TYPE = __rest
    VALUE = ""
    LEAF = 0
  }
}

# The quoted key at the front of text, quotes and escapes as written. It
# ends at the first '":' whose quote does not follow an odd run of
# backslashes; text that never closes comes back whole.
function quoted_key(text, __at, __from) {
  __from = 2

  while (1) {
    __at = index(substr(text, __from), "\":")
    if (__at == 0) {
      return text
    }

    __at = __at + __from - 1
    if (trailing_backslashes(substr(text, 1, __at - 1)) % 2 == 0) {
      return substr(text, 1, __at)
    }

    __from = __at + 2
  }
}

# How many backslashes end the text.
function trailing_backslashes(text, __n) {
  __n = 0

  while (__n < length(text) && substr(text, length(text) - __n, 1) == "\\") {
    __n++
  }

  return __n
}

# The line with its depth moved by delta.
function redepth(line, delta) {
  return (substr(line, 1, index(line, ".") - 1) + delta) "." substr(line, index(line, ".") + 1)
}

# Whether the line is a member's own line at depth 0, and not the empty
# collection's keyless line.
function is_member(line) {
  return substr(line, 1, 2) == "0." && substr(line, 3, 1) != ":"
}

# Whether the line is the keyless line of an empty collection or a scalar.
function is_keyless(line) {
  return substr(line, 1, 3) == "0.:"
}

# Loads the path segments the shell hands over in SILT_SEGMENTS, one per
# line, into SEGMENT[1..SEGMENTS].
function load_segments() {
  SEGMENTS = split(ENVIRON["SILT_SEGMENTS"], SEGMENT, "\n")

  if (ENVIRON["SILT_SEGMENTS"] == "") {
    SEGMENTS = 0
  }
}

# Whether a segment or a key is a quoted name rather than an index.
function is_name(key) {
  return substr(key, 1, 1) == "\""
}

# The text a JSON string literal spells: the quotes off and every escape
# decoded, a \u escape past ASCII as UTF-8 and a surrogate pair as one
# character.
function unwrap(literal, __out, __i, __n, __c) {
  __out = ""
  __i = 2
  __n = length(literal) - 1

  while (__i <= __n) {
    __c = substr(literal, __i, 1)

    if (__c != "\\") {
      __out = __out __c
      __i++
      continue
    }

    __c = substr(literal, __i + 1, 1)
    if (__c == "u") {
      __out = __out unescape_unicode(literal, __i + 2)
      __i = __i + 2 + UNICODE_WIDTH
    } else {
      __out = __out unescape_letter(__c)
      __i = __i + 2
    }
  }

  return __out
}

# The character a one-letter escape stands for; a letter JSON gives no
# meaning stands for itself.
function unescape_letter(letter) {
  if (letter == "n") {
    return "\n"
  }
  if (letter == "t") {
    return "\t"
  }
  if (letter == "r") {
    return "\r"
  }
  if (letter == "b") {
    return "\b"
  }
  if (letter == "f") {
    return "\f"
  }

  return letter
}

# The character of the \u escape whose four hex digits start at <at> in the
# literal, joined to the low surrogate after it when it is a high one. Sets
# UNICODE_WIDTH to how many characters the escape's digits took, 4 or 10.
function unescape_unicode(literal, at, __code, __low) {
  __code = hex(substr(literal, at, 4))
  UNICODE_WIDTH = 4

  if (__code >= 55296 && __code <= 56319 && substr(literal, at + 4, 2) == "\\u") {
    __low = hex(substr(literal, at + 6, 4))
    __code = 65536 + (__code - 55296) * 1024 + (__low - 56320)
    UNICODE_WIDTH = 10
  }

  return utf8(__code)
}

# A hex string as a number.
function hex(text, __value, __i) {
  __value = 0

  for (__i = 1; __i <= length(text); __i++) {
    __value = __value * 16 + index("0123456789abcdef", tolower(substr(text, __i, 1))) - 1
  }

  return __value
}

# The UTF-8 bytes of one code point.
function utf8(code) {
  if (code < 128) {
    return sprintf("%c", code)
  }
  if (code < 2048) {
    return sprintf("%c%c", 192 + int(code / 64), 128 + code % 64)
  }
  if (code < 65536) {
    return sprintf("%c%c%c", 224 + int(code / 4096), 128 + int(code / 64) % 64, 128 + code % 64)
  }

  return sprintf("%c%c%c%c", 240 + int(code / 262144), 128 + int(code / 4096) % 64, 128 + int(code / 64) % 64, 128 + code % 64)
}

# The text of a scalar line the way silt__string reads it: a str unwrapped,
# a null as the word null, any other as its value.
function scalar_text(line) {
  parse(line)

  if (TYPE == "str") {
    return unwrap(VALUE)
  }
  if (TYPE == "null") {
    return "null"
  }

  return VALUE
}

# Ends the run the way the shell's refusal does: the message on stderr with
# the library's prefix, and status 1.
function refuse(message) {
  printf "ERROR: silt: %s\n", message > "/dev/stderr"
  exit 1
}
