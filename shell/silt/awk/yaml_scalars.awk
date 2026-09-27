# What a YAML scalar is, shared by the reader and the writer so the writer
# quotes exactly the strings the reader would read as something else: which
# value a plain scalar names, the text a quoted one holds, and which strings
# may be written plain or as a literal block.
#
# A plain scalar is read by YAML's core schema: a null ("", "~", "null"), a
# bool ("true", "false"), a number as the schema spells one, and a string
# otherwise. "yes", "on", "007" and "1.2.3" are strings.
#
#   plain_kind("1.5")   ->  number     plain_kind("1.2.3")  ->  str
#   plain_kind("~")     ->  null       plain_kind("yes")    ->  str

# The kind of value a plain scalar names: null, bool, number or str.
function plain_kind(text) {
  if (text ~ /^(|~|null|Null|NULL)$/) {
    return "null"
  }
  if (text ~ /^(true|True|TRUE|false|False|FALSE)$/) {
    return "bool"
  }
  if (is_yaml_int(text) || is_yaml_float(text)) {
    return "number"
  }

  return "str"
}

# Whether the text is an int as YAML's core schema spells one: decimal with
# a sign, octal after 0o, or hex after 0x.
function is_yaml_int(text) {
  return text ~ /^[-+]?[0-9]+$/ || text ~ /^0o[0-7]+$/ || text ~ /^0x[0-9a-fA-F]+$/
}

# Whether the text is a float as YAML's core schema spells one, .inf and
# .nan among them.
function is_yaml_float(text) {
  if (text ~ /^[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?$/) {
    return 1
  }

  return text ~ /^[-+]?\.(inf|Inf|INF)$/ || text ~ /^\.(nan|NaN|NAN)$/
}

# A YAML number's text as ADR.20 spells it: a hex or an octal int in
# decimal, a plus sign and leading zeros off, a digit on both sides of a
# point, and .inf and .nan as inf and nan. A text ADR.20 already spells
# comes back as it is.
#
#   adr_number("0x1F")  ->  31      adr_number(".5")   ->  0.5
#   adr_number("+05")   ->  5       adr_number("-.inf")  ->  -inf
function adr_number(text) {
  if (text ~ /^0x/) {
    return from_base(substr(text, 3), 16)
  }
  if (text ~ /^0o/) {
    return from_base(substr(text, 3), 8)
  }
  if (text ~ /^[-+]?\.(inf|Inf|INF)$/) {
    return (text ~ /^-/) ? "-inf" : "inf"
  }
  if (text ~ /^\.(nan|NaN|NAN)$/) {
    return "nan"
  }

  return decimal_form(text)
}

# The digits of a number in <base> as a decimal int.
function from_base(digits, base, __value, __i) {
  __value = 0

  for (__i = 1; __i <= length(digits); __i++) {
    __value = __value * base + index("0123456789abcdef", tolower(substr(digits, __i, 1))) - 1
  }

  return sprintf("%d", __value)
}

# A decimal number's text in ADR.20's form: its sign only when minus, its
# integer part without leading zeros, its fraction with a digit after the
# point, and its exponent as written.
function decimal_form(text, __sign, __exponent, __whole, __fraction, __at) {
  __sign = (text ~ /^-/) ? "-" : ""
  sub(/^[-+]/, "", text)

  __exponent = ""
  __at = match(text, /[eE]/)
  if (__at > 0) {
    __exponent = substr(text, __at)
    text = substr(text, 1, __at - 1)
  }

  __whole = text
  __fraction = ""
  if (index(text, ".") > 0) {
    __whole = substr(text, 1, index(text, ".") - 1)
    __fraction = "." substr(text, index(text, ".") + 1)
  }
  if (__fraction == ".") {
    __fraction = ".0"
  }

  sub(/^0+/, "", __whole)
  if (__whole == "") {
    __whole = "0"
  }

  return __sign __whole __fraction __exponent
}

# The character a double-quoted escape's letter names. Refuses a letter
# YAML gives no meaning, and \0, which no line can carry.
function yaml_escape(letter) {
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
  if (letter == "v") {
    return "\013"
  }
  if (letter == "a") {
    return "\007"
  }
  if (letter == "e") {
    return "\033"
  }
  if (letter == "N") {
    return utf8(133)
  }
  if (letter == "_") {
    return utf8(160)
  }
  if (letter == "L") {
    return utf8(8232)
  }
  if (letter == "P") {
    return utf8(8233)
  }
  if (letter == "\"" || letter == "\\" || letter == "/" || letter == " " || letter == "\t") {
    return letter
  }

  refuse_yaml("an escape YAML has no name for: \\" letter)
}

# The width in hex digits of a \x, \u or \U escape, or 0 for a letter that
# opens none.
function hex_width(letter) {
  if (letter == "x") {
    return 2
  }
  if (letter == "u") {
    return 4
  }
  if (letter == "U") {
    return 8
  }

  return 0
}

# The text between a pair of double quotes, its escapes read: a letter's
# character, or the code point a \x, \u or \U spells as UTF-8. Sets
# ESCAPE_WIDTH to how many characters the escape at <at> took.
function read_escape(inner, at, __letter, __width) {
  __letter = substr(inner, at + 1, 1)
  __width = hex_width(__letter)

  if (__width == 0) {
    ESCAPE_WIDTH = 2
    return yaml_escape(__letter)
  }

  ESCAPE_WIDTH = 2 + __width
  return utf8(hex(substr(inner, at + 2, __width)))
}

# The text between a pair of double quotes, its escapes read.
function unescape_double(inner, __out, __i, __c) {
  __out = ""
  __i = 1

  while (__i <= length(inner)) {
    __c = substr(inner, __i, 1)

    if (__c == "\\") {
      __out = __out read_escape(inner, __i)
      __i = __i + ESCAPE_WIDTH
    } else {
      __out = __out __c
      __i++
    }
  }

  return __out
}

# The text between a pair of single quotes, where '' is one quote.
function unescape_single(inner) {
  gsub(/''/, "'", inner)
  return inner
}

# The text a quoted scalar holds, quoted being the scalar with its quotes on.
function unquote(quoted, __inner) {
  __inner = substr(quoted, 2, length(quoted) - 2)

  if (substr(quoted, 1, 1) == "\"") {
    return unescape_double(__inner)
  }

  return unescape_single(__inner)
}

# Whether a string can be written plain and read back as the same string:
# words of safe characters with single spaces between, that no YAML reader,
# old or new, takes for a number, a bool or a null.
function is_plain_safe(text) {
  if (text !~ /^[A-Za-z_\/][A-Za-z0-9_.\/@%+=-]*( [A-Za-z0-9_.\/@%+=-]+)*$/) {
    return 0
  }
  if (text ~ /^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$/) {
    return 0
  }

  return plain_kind(text) == "str"
}

# Whether a string can be written as a literal block and read back as the
# same string: it runs over lines, opens on a line that holds something and
# does not start with a space, and has no carriage return and no line of
# spaces alone, which a block cannot tell from an empty one.
function is_block_safe(text) {
  if (index(text, "\n") == 0 || text ~ /\r/) {
    return 0
  }
  if (text ~ /^[ \n]/ || text ~ /(^|\n)[ \t]+(\n|$)/) {
    return 0
  }

  return 1
}
