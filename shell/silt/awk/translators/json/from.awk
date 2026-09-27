# The JSON document on stdin as a SILT document, with the members of every
# map in the order the JSON wrote them: silt__from_json. The text is read whole, then walked once left to
# right in one of seven states, each named for what the grammar expects
# next. Every value is written as it is met: a str as its literal untouched,
# a number by ADR.20's patterns, a collection opened on its bracket and
# closed on the other. A map that holds a key twice, a number outside 64
# bits or binary64, and any text that is not JSON are refused, naming the
# line. Loaded after lines.awk and translators/write.awk.
#
#   {"b":[1,"x"],"a":null}  ->  0."b":list
#                               1.0:int=1
#                               1.1:str="x"
#                               0."a":null

# Ends the run naming the line the reader stands on.
function refuse_json(why) {
  refuse("json line " AT_LINE ": " why)
}

# Moves past JSON's whitespace, counting the lines passed.
function skip_space(__c) {
  while (1) {
    __c = substr(TEXT, POS, 1)

    if (__c == "\n") {
      AT_LINE++
    } else if (__c != " " && __c != "\t" && __c != "\r") {
      return
    }

    POS++
  }
}

# Moves past a byte-order mark at the front of the text, which JSON's
# readers may ignore.
function skip_bom() {
  if (substr(TEXT, 1, 3) == "\357\273\277") {
    POS = 4
  }
}

# The str literal at POS, which sits on its opening quote, with POS moved
# past its closing one: the quotes and escapes as written, each escape
# checked against JSON's, and a raw control character refused.
function read_string(__start, __c) {
  __start = POS
  POS++

  while (1) {
    __c = substr(TEXT, POS, 1)

    if (__c == "\"") {
      POS++
      return substr(TEXT, __start, POS - __start)
    }
    if (__c == "") {
      refuse_json("a string that never closes")
    }
    if (index(CONTROL, __c) > 0) {
      refuse_json("a control character inside a string")
    }

    if (__c == "\\") {
      skip_escape()
    } else {
      POS++
    }
  }
}

# Moves POS past the escape it sits on, refused when JSON has no such
# escape.
function skip_escape(__letter) {
  __letter = substr(TEXT, POS + 1, 1)

  if (__letter != "" && index("\"\\/bfnrt", __letter) > 0) {
    POS = POS + 2
    return
  }
  if (__letter == "u" && substr(TEXT, POS + 2, 4) ~ /^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$/) {
    POS = POS + 6
    return
  }

  refuse_json("an escape JSON has no name for: \\" __letter)
}

# The number at POS, with POS moved past it: the run of a number's
# characters, refused when it is not spelled as JSON spells one.
function read_number(__start, __text) {
  __start = POS
  while (substr(TEXT, POS, 1) ~ /^[-+.0-9eE]$/) {
    POS++
  }

  __text = substr(TEXT, __start, POS - __start)
  if (__text !~ /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) {
    refuse_json("not a JSON number: " __text)
  }

  return __text
}

# The word at POS, with POS moved past it: the run of lowercase letters,
# which is empty on anything else.
function read_word(__start) {
  __start = POS
  while (substr(TEXT, POS, 1) ~ /^[a-z]$/) {
    POS++
  }

  return substr(TEXT, __start, POS - __start)
}

# Writes the value a word spells, true, false or null; refuses any other
# word, and the end of the text where a value was expected.
function write_word(key, word) {
  if (word == "true" || word == "false") {
    write_scalar(key, "bool", word)
    return
  }
  if (word == "null") {
    write_scalar(key, "null", "")
    return
  }

  if (substr(TEXT, POS, 1) == "") {
    refuse_json("the document ends before its value")
  }
  refuse_json("not a JSON value: " word substr(TEXT, POS, 1))
}

# Opens a map under the key read and expects its first key or its closer.
function open_map() {
  open_collection("map", KEY_READ)
  POS++
  STATE = "first_key"
}

# Opens a list under the key read and expects its first value or its closer.
function open_list() {
  open_collection("list", KEY_READ)
  POS++
  STATE = "first_value"
}

# Closes the collection open, moves past its closer, and expects what
# follows a value.
function close_on_bracket() {
  close_collection()
  POS++
  STATE = "more"
}

# Value: a bracket opens a collection under the key read, a quote a str, a
# digit or a minus a number, and anything else is one of the three words.
function expect_value(c) {
  if (c == "{") {
    open_map()
  } else if (c == "[") {
    open_list()
  } else if (c == "\"") {
    write_scalar(KEY_READ, "str", read_string())
    STATE = "more"
  } else if (c ~ /^[-0-9]$/) {
    write_number(KEY_READ, read_number())
    STATE = "more"
  } else {
    write_word(KEY_READ, read_word())
    STATE = "more"
  }
}

# First value: a list just opened closes on its bracket, or holds a value.
function expect_first_value(c) {
  if (c == "]") {
    close_on_bracket()
  } else {
    STATE = "value"
  }
}

# First key: a map just opened closes on its bracket, or holds a member.
function expect_first_key(c) {
  if (c == "}") {
    close_on_bracket()
  } else {
    STATE = "key"
  }
}

# Key: a member opens with its key, a str literal, and a colon follows.
function expect_key(c) {
  if (c != "\"") {
    refuse_json("a member with no key")
  }

  KEY_READ = read_string()
  STATE = "colon"
}

# Colon: the member's value follows it.
function expect_colon(c) {
  if (c != ":") {
    refuse_json("a key with no colon after it")
  }

  POS++
  STATE = "value"
}

# More: after a value, a comma brings the next member of the collection
# open, its closer ends it, and with none open the document is done.
function expect_more(c) {
  KEY_READ = ""

  if (OPEN == 0) {
    STATE = "end"
  } else if (c == ",") {
    POS++
    STATE = (OPEN_KIND[OPEN] == "map") ? "key" : "value"
  } else if (c == ((OPEN_KIND[OPEN] == "map") ? "}" : "]")) {
    close_on_bracket()
  } else {
    refuse_json("a comma or the closing bracket expected")
  }
}

# End: nothing but whitespace follows the document's value.
function expect_end(c) {
  if (c != "") {
    refuse_json("text after the document's value")
  }

  STATE = "done"
}

# Walks the text once, one state at a time, until the document is done.
function read_document(__c) {
  sub(/\n$/, "", TEXT)
  skip_bom()

  while (STATE != "done") {
    skip_space()
    __c = substr(TEXT, POS, 1)

    if (STATE == "value") {
      expect_value(__c)
    } else if (STATE == "first_value") {
      expect_first_value(__c)
    } else if (STATE == "first_key") {
      expect_first_key(__c)
    } else if (STATE == "key") {
      expect_key(__c)
    } else if (STATE == "colon") {
      expect_colon(__c)
    } else if (STATE == "more") {
      expect_more(__c)
    } else {
      expect_end(__c)
    }
  }
}

# Keeps the text whole, its line ends restored, for END.
function main() {
  TEXT = TEXT $0 "\n"
}

BEGIN {
  for (CONTROL_I = 1; CONTROL_I < 32; CONTROL_I++) {
    CONTROL = CONTROL sprintf("%c", CONTROL_I)
  }
  TEXT = ""
  POS = 1
  AT_LINE = 1
  KEY_READ = ""
  STATE = "value"
}

END {
  read_document()
  print_written()
}

{ main() }
