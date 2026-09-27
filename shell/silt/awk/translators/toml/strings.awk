# TOML's four string forms read into the text each holds: a basic string
# in double quotes with escapes, a literal string in single quotes with
# none, and each in a multi-line form between three of its quotes, where a
# line end just after the opening quotes is dropped, a CRLF is one LF, and
# in the basic form a backslash that ends a line drops the whitespace up to
# the next character that is not. A one-line string the line ends before,
# a control character other than a tab, and an escape TOML gives no meaning
# are refused. Loaded after awk/lines.awk and text.awk beside this one.
#
#   read_string() on  "a\tb"     ->  a<tab>b
#   read_string() on  'C:\path'  ->  C:\path

# The text of the string the reader stands on, in any of the four forms,
# the reader moved past its closing quotes.
function read_string(__quote) {
  __quote = peek()

  if (substr(TEXT, POS, 3) == __quote __quote __quote) {
    step_by(3)
    skip_first_line_end()
    return (__quote == "\"") ? read_multiline_basic() : read_multiline_literal()
  }

  step()
  return (__quote == "\"") ? read_basic() : read_literal()
}

# Steps over the line end that follows a multi-line string's opening
# quotes, which TOML drops.
function skip_first_line_end() {
  if (at_line_end()) {
    step_line_end()
  }
}

# The text up to the closing quote of a one-line basic string, its escapes
# read.
function read_basic(__out, __c) {
  __out = ""

  while (1) {
    __c = peek()

    if (__c == "\"") {
      step()
      return __out
    }
    refuse_unclosed(__c, "a basic string")

    if (__c == "\\") {
      __out = __out read_toml_escape()
    } else {
      __out = __out __c
      step()
    }
  }
}

# The text up to the closing quote of a one-line literal string, as
# written.
function read_literal(__out, __c) {
  __out = ""

  while (1) {
    __c = peek()

    if (__c == "'") {
      step()
      return __out
    }
    refuse_unclosed(__c, "a literal string")

    __out = __out __c
    step()
  }
}

# Refuses a one-line string the line ends before, and a control character
# inside one.
function refuse_unclosed(c, what) {
  if (c == "" || c == "\n" || c == "\r") {
    refuse_toml(what " that never closes")
  }
  if (is_control(c)) {
    refuse_toml("a control character inside " what)
  }
}

# The character the escape the reader stands on names, the reader moved
# past it: a letter's character, or the code point of a \x, a \u or a \U
# as UTF-8; \x is TOML 1.1's and read here because yq writes it. Refuses a
# letter TOML gives no meaning, an escape short of its hex digits, and a
# code that is no Unicode scalar value.
function read_toml_escape(__letter, __width, __hex) {
  __letter = peek_at(1)
  __width = hex_escape_width(__letter)

  if (__width == 0) {
    step_by(2)
    return toml_escape(__letter)
  }

  __hex = substr(TEXT, POS + 2, __width)
  if (length(__hex) != __width || __hex !~ /^[0-9A-Fa-f]+$/) {
    refuse_toml("a \\" __letter " escape without its " __width " hex digits")
  }

  step_by(2 + __width)
  return utf8(scalar_value(hex(__hex)))
}

# How many hex digits the escape a letter opens takes: two for \x, four
# for \u, eight for \U, and none for any other letter.
function hex_escape_width(letter) {
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

# The character a one-letter escape names in a basic string. Refuses a
# letter TOML gives no meaning.
function toml_escape(letter) {
  if (letter == "b") {
    return "\b"
  }
  if (letter == "t") {
    return "\t"
  }
  if (letter == "n") {
    return "\n"
  }
  if (letter == "f") {
    return "\f"
  }
  if (letter == "r") {
    return "\r"
  }
  if (letter == "\"" || letter == "\\") {
    return letter
  }

  refuse_toml("an escape TOML has no name for: \\" letter)
}

# The code point when it is a Unicode scalar value a line can carry.
# Refuses a surrogate, a code past U+10FFFF, and \0, which no line can
# carry.
function scalar_value(code) {
  if ((code >= 55296 && code <= 57343) || code > 1114111) {
    refuse_toml("an escape that is no Unicode scalar value")
  }
  if (code == 0) {
    refuse_toml("a \\u0000 escape, which no line can carry")
  }

  return code
}

# The text up to the closing quotes of a multi-line basic string, its
# escapes read, a CRLF made one LF, and the whitespace after a backslash
# that ends a line dropped up to the next character that is not.
function read_multiline_basic(__out, __c) {
  __out = ""

  while (1) {
    __c = peek()

    if (__c == "\"" && substr(TEXT, POS, 3) == "\"\"\"") {
      return __out closing_quotes("\"")
    }
    if (__c == "") {
      refuse_toml("a multi-line basic string that never closes")
    }

    if (__c == "\\" && backslash_ends_line()) {
      skip_ws_and_line_ends()
    } else if (__c == "\\") {
      __out = __out read_toml_escape()
    } else {
      __out = __out multiline_char(__c)
    }
  }
}

# The text up to the closing quotes of a multi-line literal string, as
# written but for a CRLF, which is one LF.
function read_multiline_literal(__out, __c) {
  __out = ""

  while (1) {
    __c = peek()

    if (__c == "'" && substr(TEXT, POS, 3) == "'''") {
      return __out closing_quotes("'")
    }
    if (__c == "") {
      refuse_toml("a multi-line literal string that never closes")
    }

    __out = __out multiline_char(__c)
  }
}

# One character of a multi-line string as its text holds it, the reader
# moved past it: a CRLF as one LF, a control character other than a tab or
# a line end refused, and any other as written.
function multiline_char(c) {
  if (c == "\r" && peek_at(1) == "\n") {
    step_by(2)
    return "\n"
  }
  if (c != "\n" && is_control(c)) {
    refuse_toml("a control character inside a multi-line string")
  }

  step()
  return c
}

# Whether the backslash the reader stands on ends its line: nothing but
# whitespace sits between it and the line end.
function backslash_ends_line(__i, __c) {
  __i = 1

  while (1) {
    __c = peek_at(__i)

    if (__c == "\n" || (__c == "\r" && peek_at(__i + 1) == "\n")) {
      return 1
    }
    if (__c != " " && __c != "\t") {
      return 0
    }

    __i++
  }
}

# Steps over a backslash that ends its line and the whitespace and line
# ends after it.
function skip_ws_and_line_ends() {
  step()

  while (peek() == " " || peek() == "\t" || peek() == "\n" || peek() == "\r") {
    step()
  }
}

# The quotes that belong to the text at the closing quotes of a multi-line
# string, the reader moved past the run: TOML lets one or two quotes sit
# just inside the three that close the string, so a run of four or five
# keeps one or two, and a longer run is refused.
function closing_quotes(quote, __run) {
  __run = 0

  while (peek() == quote) {
    __run++
    step()
  }

  if (__run > 5) {
    refuse_toml("too many quotes closing a multi-line string")
  }

  return substr(quote quote, 1, __run - 3)
}
