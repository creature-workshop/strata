# The value the reader stands on, as a node of the tree, and the key before
# it: a string in any of its four forms as a str, an array as a list of the
# values between its brackets, which may run over lines and end in a comma,
# an inline table as a map of the pairs between its braces on one line, and
# a bare token as the bool, the number or the date-time it spells. A key is
# segments bare or quoted, joined by dots. Loaded after awk/lines.awk,
# translators/write.awk and translators/numbers.awk, and every file beside
# this one but from.awk.
#
#   read_value() on  [1, "x", {a = true}]  ->  a list of an int, a str and a map

# The node of the value the reader stands on, the reader moved past it.
function read_value(__c) {
  __c = peek()

  if (__c == "\"" || __c == "'") {
    return scalar_node("str", wrap(read_string()))
  }
  if (__c == "[") {
    return read_array()
  }
  if (__c == "{") {
    return read_inline_table()
  }

  return token_node(read_token())
}

# The bare token the reader stands on, the reader moved past it: a run of
# the characters a bool, a number or a date-time is spelled with, and the
# clock that may follow a date after one space. Refused when empty.
function read_token(__start, __token) {
  __start = POS
  skip_token_chars()

  __token = substr(TEXT, __start, POS - __start)
  if (__token == "") {
    refuse_toml("a value expected: " rest_of_line())
  }

  if (is_date(__token) && clock_follows()) {
    step()
    skip_token_chars()
    __token = substr(TEXT, __start, POS - __start)
  }

  return __token
}

# Steps over the characters a bare token is spelled with.
function skip_token_chars() {
  while (peek() ~ /^[0-9A-Za-z_+.:-]$/) {
    step()
  }
}

# Whether a clock follows the reader after one space, which joins a date to
# its clock as T does.
function clock_follows() {
  return peek() == " " && peek_at(1) ~ /^[0-9]$/ && peek_at(2) ~ /^[0-9]$/ && peek_at(3) == ":"
}

# The node of the array the reader stands on, the reader moved past its
# closing bracket: a static array of the values between the brackets, where
# whitespace, line ends and comments sit anywhere, and a comma may end the
# list.
function read_array(__node) {
  __node = new_node("array")
  N_STATE[__node] = "static"
  step()

  while (1) {
    skip_blank_lines()

    if (peek() == "]") {
      step()
      return __node
    }
    if (peek() == "") {
      refuse_toml("an array that never closes")
    }

    add_element(__node, read_value())
    expect_array_separator()
  }
}

# Steps over the comma after an array's value, or stands on the bracket
# that closes the array. Refuses anything else.
function expect_array_separator() {
  skip_blank_lines()

  if (peek() == ",") {
    step()
  } else if (peek() != "]") {
    refuse_toml("a comma or the closing bracket expected in an array: " rest_of_line())
  }
}

# The node of the inline table the reader stands on, the reader moved past
# its closing brace: a table of the pairs between the braces, on one line,
# with no comma after the last, and closed to every later addition.
function read_inline_table(__node) {
  __node = new_node("table")
  N_STATE[__node] = "inline"
  step()
  skip_ws()

  if (peek() == "}") {
    step()
    return __node
  }

  while (1) {
    read_pair(__node)
    skip_ws()

    if (peek() == "}") {
      step()
      return __node
    }

    expect_inline_comma()
  }
}

# Steps over the comma between two pairs of an inline table and the
# whitespace after it. Refuses a line end or the end of the text on either
# side of it, a comma with no pair after it, and anything else.
function expect_inline_comma() {
  if (peek() != ",") {
    refuse_toml(inline_table_fault())
  }

  step()
  skip_ws()
  if (peek() == "}") {
    refuse_toml("a comma with no pair after it in an inline table")
  }
  if (ends_inline_line()) {
    refuse_toml("an inline table that runs over lines")
  }
}

# Whether the reader stands where an inline table's line ends before the
# table closes: a line end, a lone carriage return, or the end of the text.
function ends_inline_line() {
  return peek() == "" || peek() == "\r" || at_line_end()
}

# Why an inline table cannot go on from the character the reader stands on.
function inline_table_fault() {
  if (ends_inline_line()) {
    return "an inline table that runs over lines"
  }

  return "a comma or the closing brace expected in an inline table: " rest_of_line()
}

# Reads the key the reader stands on into PATH_KEY[1..PATH_N]: segments
# bare, or quoted in either one-line form, joined by dots with whitespace
# around them.
function read_key() {
  PATH_N = 0

  while (1) {
    skip_ws()
    PATH_KEY[++PATH_N] = read_key_segment()
    skip_ws()

    if (peek() != ".") {
      return
    }

    step()
  }
}

# One segment of a key, the reader moved past it: a quoted string in a
# one-line form, or a bare run of letters, digits, underscores and dashes.
# Refuses a multi-line string, and a segment with nothing in it.
function read_key_segment(__start, __c) {
  __c = peek()

  if (__c == "\"" || __c == "'") {
    if (substr(TEXT, POS, 3) == __c __c __c) {
      refuse_toml("a multi-line string as a key")
    }
    return read_string()
  }

  __start = POS
  while (peek() ~ /^[A-Za-z0-9_-]$/) {
    step()
  }
  if (POS == __start) {
    refuse_toml("a key expected: " rest_of_line())
  }

  return substr(TEXT, __start, POS - __start)
}

# Reads the pair the reader stands on, "key = value", into <table>: the
# key's segments but the last name tables on the way, and the last takes
# the value. The reader is moved past the value.
function read_pair(table, __i, __last) {
  read_key()
  skip_ws()

  if (peek() != "=") {
    refuse_toml("an equals sign expected after the key: " rest_of_line())
  }
  step()
  skip_ws()

  for (__i = 1; __i < PATH_N; __i++) {
    table = descend_dotted(table, PATH_KEY[__i])
  }
  __last = PATH_KEY[PATH_N]

  add_child(table, __last, read_value())
}
