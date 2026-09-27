# The lines of a YAML document as the reader walks them: each kept as
# written, then read for its indentation and its text with the comment and
# the trailing spaces off, and the line the reader stands on. Loaded
# after awk/lines.awk by every program that reads or writes YAML.
#
#   Y_N          how many lines the document has
#   Y_RAW[i]     line i as written, which a block scalar reads
#   Y_INDENT[i]  the spaces line i starts with
#   Y_TEXT[i]    line i past its indentation, comment and trailing spaces
#                off, empty for a line that holds nothing
#   Y_POS        the line the reader stands on
#
#   "  key: 'a # b'  # note"  ->  Y_INDENT 2, Y_TEXT "key: 'a # b'"

# Ends the run naming the line the reader stands on and why it cannot be
# read.
function refuse_yaml(why) {
  refuse("yaml line " Y_POS ": " why ": " Y_RAW[Y_POS])
}

# Keeps one line of the document as written, a carriage return at its end
# taken off, since a file from a system that ends lines that way is
# converted once, here.
function keep_line(raw) {
  sub(/\r$/, "", raw)
  Y_RAW[++Y_N] = raw
}

# The spaces a line starts with.
function indent_of(raw) {
  match(raw, /^ */)
  return RLENGTH
}

# Whether a quote character at position i of text opens a quoted scalar: it
# does at the start of a value, and inside a word ("don't") it is a letter.
function opens_quote(text, i) {
  return i == 1 || substr(text, i - 1, 1) ~ /[ \[{,]/
}

# The position just past the quoted scalar that opens at position i of text,
# or 0 when the line ends before the quote closes.
function quote_end(text, i, __quote, __c) {
  __quote = substr(text, i, 1)

  for (i++; i <= length(text); i++) {
    __c = substr(text, i, 1)

    if (__c == "\\" && __quote == "\"") {
      i++
    } else if (__c == __quote && __quote == "'" && substr(text, i + 1, 1) == "'") {
      i++
    } else if (__c == __quote) {
      return i + 1
    }
  }

  return 0
}

# The position just past the quoted scalar that opens at position i of
# text: 0 when no quoted scalar opens there, and -1 when one opens and the
# line ends before it closes.
function quoted_span_end(text, i, __c, __end) {
  __c = substr(text, i, 1)
  if ((__c != "\"" && __c != "'") || !opens_quote(text, i)) {
    return 0
  }

  __end = quote_end(text, i)
  return (__end == 0) ? -1 : __end
}

# Whether a "#" at position i of text opens a comment: it does when it
# starts the text or follows a space.
function opens_comment(text, i) {
  return substr(text, i, 1) == "#" && (i == 1 || substr(text, i - 1, 1) == " ")
}

# Text with its comment taken off: the first "#" that opens one outside any
# quoted scalar.
function without_comment(text, __i, __end) {
  for (__i = 1; __i <= length(text); __i++) {
    __end = quoted_span_end(text, __i)

    if (__end < 0) {
      return text
    }
    if (__end > 0) {
      __i = __end - 1
    } else if (opens_comment(text, __i)) {
      return substr(text, 1, __i - 1)
    }
  }

  return text
}

# Text with the spaces at its end taken off.
function rtrim(text) {
  sub(/[ \t]+$/, "", text)
  return text
}

# Text with the spaces at both ends taken off.
function trim(text) {
  sub(/^[ \t]+/, "", text)
  return rtrim(text)
}

# Reads every kept line's indentation and text, and stands on the first.
function read_lines(__i) {
  for (__i = 1; __i <= Y_N; __i++) {
    Y_INDENT[__i] = indent_of(Y_RAW[__i])
    Y_TEXT[__i] = rtrim(without_comment(substr(Y_RAW[__i], Y_INDENT[__i] + 1)))
  }

  Y_POS = 1
}

# Steps over the lines that hold nothing.
function skip_blank() {
  while (Y_POS <= Y_N && Y_TEXT[Y_POS] == "") {
    Y_POS++
  }
}

# Whether no line that holds something is left.
function at_end() {
  skip_blank()
  return Y_POS > Y_N
}
