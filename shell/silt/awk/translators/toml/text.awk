# The text of a TOML document as the reader walks it: kept whole, then read
# left to right from a cursor that counts the lines it passes, so a refusal
# names the line the reader stands on. TOML's whitespace is a space or a
# tab, a line ends in LF or CRLF, and a comment runs from "#" to the end of
# its line. Loaded after awk/lines.awk by every program that reads TOML.
#
#   TEXT      the document, whole
#   POS       the character the reader stands on
#   AT_LINE   the line POS is on

# Ends the run naming the line the reader stands on.
function refuse_toml(why) {
  refuse("toml line " AT_LINE ": " why)
}

# Keeps one line of the document, its line end restored, for END.
function keep_text(raw) {
  TEXT = TEXT raw "\n"
}

# The character the reader stands on, empty at the end of the text.
function peek() {
  return substr(TEXT, POS, 1)
}

# The character <ahead> past the one the reader stands on.
function peek_at(ahead) {
  return substr(TEXT, POS + ahead, 1)
}

# Steps past the character the reader stands on, counting a line end.
function step() {
  if (substr(TEXT, POS, 1) == "\n") {
    AT_LINE++
  }

  POS++
}

# Steps past n characters.
function step_by(n) {
  while (n > 0) {
    step()
    n--
  }
}

# The text from the reader to the end of its line.
function rest_of_line(__end) {
  __end = index(substr(TEXT, POS), "\n")

  return (__end == 0) ? substr(TEXT, POS) : substr(TEXT, POS, __end - 1)
}

# Whether the character is a control character TOML forbids raw: one below
# a space other than a tab, or a delete.
function is_control(c) {
  return (c != "" && c != "\t" && c < " ") || c == "\177"
}

# Whether the reader stands on a line end, LF or CRLF.
function at_line_end() {
  return peek() == "\n" || (peek() == "\r" && peek_at(1) == "\n")
}

# Steps over the line end the reader stands on.
function step_line_end() {
  if (peek() == "\r") {
    step()
  }

  step()
}

# Steps over the spaces and tabs the reader stands on.
function skip_ws() {
  while (peek() == " " || peek() == "\t") {
    step()
  }
}

# Steps over the comment the reader stands on, up to its line end. A control
# character inside it is refused, as TOML forbids one.
function skip_comment() {
  if (peek() != "#") {
    return
  }

  while (peek() != "" && !at_line_end()) {
    if (is_control(peek())) {
      refuse_toml("a control character in a comment")
    }

    step()
  }
}

# Steps over the end of the line the reader stands on, whitespace and a
# comment first, refused when the line holds anything else after <what>.
# The end of the text ends a line too.
function end_line(what) {
  skip_ws()
  skip_comment()

  if (at_line_end()) {
    step_line_end()
    return
  }
  if (peek() != "") {
    refuse_toml("text after " what ": " rest_of_line())
  }
}

# Steps over the lines that hold nothing but whitespace and comments, to the
# first character of the next line that holds something, or to the end. A
# carriage return with no line feed after it is refused.
function skip_blank_lines() {
  while (1) {
    skip_ws()
    skip_comment()

    if (peek() == "\r" && peek_at(1) != "\n") {
      refuse_toml("a carriage return with no line feed after it")
    }
    if (!at_line_end()) {
      return
    }

    step_line_end()
  }
}
