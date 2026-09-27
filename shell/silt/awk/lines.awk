# The line library every SILT awk program loads first: a line into its
# parts, a line moved to another depth, and the path segments the shell
# hands over. Loaded with -f ahead of the program, so its functions are
# shared and its one rule runs on no line.

# Reads a line into DEPTH, KEY, TYPE, VALUE and LEAF, the way the shell's
# parse does: the key a quoted literal under a map, bare digits under a list,
# empty on a keyless line; LEAF 1 when the line carries a value.
function parse(line, __rest, __head, __odd) {
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

# The quoted key at the front of text, quotes and escapes as written: it
# ends at the first '":' whose quote does not follow an odd run of
# backslashes.
function quoted_key(text, __at, __from, __run) {
  __from = 2
  while (1) {
    __at = index(substr(text, __from), "\":")
    if (__at == 0) {
      return text
    }
    __at = __at + __from - 1
    __run = trailing_backslashes(substr(text, 1, __at - 1))
    if (__run % 2 == 0) {
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

# Loads the path segments the shell hands over in SILT_SEGMENTS, one per
# line, into SEGMENT[1..SEGMENTS].
function load_segments(__i) {
  SEGMENTS = split(ENVIRON["SILT_SEGMENTS"], SEGMENT, "\n")
  if (ENVIRON["SILT_SEGMENTS"] == "") {
    SEGMENTS = 0
  }
}

# The text a JSON string literal spells: the quotes off and every escape
# decoded, a \u escape past ASCII as UTF-8.
function unwrap(literal, __out, __i, __c, __n, __code, __low) {
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
    if (__c == "n") { __out = __out "\n" }
    else if (__c == "t") { __out = __out "\t" }
    else if (__c == "r") { __out = __out "\r" }
    else if (__c == "b") { __out = __out "\b" }
    else if (__c == "f") { __out = __out "\f" }
    else if (__c == "u") {
      __code = hex(substr(literal, __i + 2, 4))
      __i = __i + 4
      if (__code >= 55296 && __code <= 56319 && substr(literal, __i + 2, 2) == "\\u") {
        __low = hex(substr(literal, __i + 4, 4))
        __code = 65536 + (__code - 55296) * 1024 + (__low - 56320)
        __i = __i + 6
      }
      __out = __out utf8(__code)
    }
    else { __out = __out __c }
    __i = __i + 2
  }
  return __out
}

# A hex string as a number.
function hex(text, __v, __i, __d) {
  __v = 0
  for (__i = 1; __i <= length(text); __i++) {
    __d = index("0123456789abcdef", tolower(substr(text, __i, 1))) - 1
    __v = __v * 16 + __d
  }
  return __v
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
