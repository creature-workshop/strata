# The TOML document on stdin as a SILT document, with the members of every
# map in the order the TOML first wrote them: silt__from_toml. The text is read whole, then walked once: a
# header names the table the pairs after it fill, and a pair puts its value
# under its key, a dotted key naming tables on the way. Since a header may
# name a table from anywhere in the document, the values are held in a tree
# (tree.awk) and written once the text is read. Every construct of TOML
# 1.0 is read: the four string forms, integers in four bases, floats,
# booleans, date-times, arrays, inline tables, tables and arrays of tables.
# A spelling Strata has no primitive for, a number outside ADR.20's
# patterns or a local date-time, is kept as the map ADR.20 gives it, and
# what TOML forbids is refused, naming the line. Loaded after awk/lines.awk,
# translators/write.awk, translators/numbers.awk and every other
# file beside this one.
#
#   [a]              ->  0."a":map
#   b = [1, "x"]         1."b":list
#                        2.0:int=1
#                        2.1:str="x"

# Moves past a byte-order mark at the front of the text.
function skip_bom() {
  if (substr(TEXT, 1, 3) == "\357\273\277") {
    POS = 4
  }
}

# Reads the header the reader stands on, "[key]" or "[[key]]", closing the
# body before it, and makes the table it names the body the pairs after it
# fill.
function read_header(__array, __i, __table) {
  close_dotted()
  __array = (peek_at(1) == "[")
  step_by(__array ? 2 : 1)
  read_key()
  expect_closer(__array)

  __table = ROOT
  for (__i = 1; __i < PATH_N; __i++) {
    __table = descend_header(__table, PATH_KEY[__i])
  }

  BODY = __array ? append_table(__table, PATH_KEY[PATH_N]) : define_table(__table, PATH_KEY[PATH_N])
}

# Steps over the bracket or the pair of brackets that closes a header.
# Refuses anything else.
function expect_closer(array) {
  if (substr(TEXT, POS, array ? 2 : 1) != (array ? "]]" : "]")) {
    refuse_toml("a table header that never closes: " rest_of_line())
  }

  step_by(array ? 2 : 1)
}

# Reads the line the reader stands on, which holds something: a header, or
# a pair of the body open, then the end of the line.
function read_line() {
  if (peek() == "[") {
    read_header()
    end_line("the table header")
  } else {
    read_pair(BODY)
    end_line("the value")
  }
}

# Reads the whole text into the tree, then writes the tree.
function read_document() {
  skip_bom()
  ROOT = new_node("table")
  N_STATE[ROOT] = "defined"
  BODY = ROOT

  skip_blank_lines()
  while (peek() != "") {
    read_line()
    skip_blank_lines()
  }

  close_dotted()
  emit(ROOT, "")
}

# Keeps the text whole, its line ends restored, for END.
function main() {
  keep_text($0)
}

BEGIN {
  TEXT = ""
  POS = 1
  AT_LINE = 1
  NODES = 0
  DOTTED_N = 0
}

END {
  read_document()
  print_written()
}

{ main() }
