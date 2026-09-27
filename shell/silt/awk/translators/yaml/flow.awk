# A YAML flow collection written on one line, "[a, b]" or "{a: 1, b: [x]}",
# read into the SILT writer: the text is walked once, left to right, in one
# of six states named for what comes next, a bracket opening a collection
# and its pair closing it. One that runs over lines is refused. Loaded after
# translators/write.awk and lines.awk, scalars.awk and values.awk beside
# this one.
#
#   read_flow("\"a\"", "[x, {b: 1}]")  ->  0."a":list
#                                          1.0:str="x"
#                                          1.1:map
#                                          2."b":int=1

# Steps over spaces.
function flow_skip_spaces() {
  while (substr(F_TEXT, F_POS, 1) == " ") {
    F_POS++
  }
}

# The character the reader stands on, spaces stepped over, refused at the
# end of the line while a collection is open.
function flow_peek(__c) {
  flow_skip_spaces()
  __c = substr(F_TEXT, F_POS, 1)

  if (__c == "" && F_DEPTH > 0) {
    refuse_yaml("a flow collection that runs over lines")
  }

  return __c
}

# The text of the quoted scalar the reader stands on, the reader moved past
# it.
function flow_quoted(__end, __quoted) {
  __end = quote_end(F_TEXT, F_POS)
  if (__end == 0) {
    refuse_yaml("a quoted scalar that runs over lines")
  }

  __quoted = substr(F_TEXT, F_POS, __end - F_POS)
  F_POS = __end
  return unquote(__quoted)
}

# The plain scalar the reader stands on, up to the first of <stops>, with
# the spaces at its ends off and the reader moved past it.
function flow_plain(stops, __start) {
  __start = F_POS
  while (F_POS <= length(F_TEXT) && index(stops, substr(F_TEXT, F_POS, 1)) == 0) {
    F_POS++
  }

  return trim(substr(F_TEXT, __start, F_POS - __start))
}

# Opens a collection under the key read and steps onto its first member.
function flow_open(kind, first) {
  open_collection(kind, F_KEY)
  F_DEPTH++
  F_POS++
  F_KEY = ""
  F_STATE = first
}

# Closes the collection open, steps past its closer, and expects what
# follows a member.
function flow_close() {
  close_collection()
  F_DEPTH--
  F_POS++
  F_STATE = "more"
}

# Value: a bracket opens a collection, a quote a str, and anything else is
# a plain scalar up to the next mark.
function flow_value(c) {
  if (c == "[") {
    flow_open("list", "first_value")
  } else if (c == "{") {
    flow_open("map", "first_key")
  } else if (c == "\"" || c == "'") {
    write_scalar(F_KEY, "str", wrap(flow_quoted()))
    F_STATE = "more"
  } else {
    refuse_unread(substr(F_TEXT, F_POS))
    write_plain(F_KEY, flow_plain(",]}"))
    F_STATE = "more"
  }
}

# First value: a list just opened closes on its bracket, or holds a value.
function flow_first_value(c) {
  if (c == "]") {
    flow_close()
  } else {
    F_STATE = "value"
  }
}

# First key: a map just opened closes on its bracket, or holds a member.
function flow_first_key(c) {
  if (c == "}") {
    flow_close()
  } else {
    F_STATE = "key"
  }
}

# Key: a member's key, quoted or plain up to its colon.
function flow_key(c) {
  if (c == "\"" || c == "'") {
    F_KEY = wrap(flow_quoted())
  } else {
    refuse_unread(substr(F_TEXT, F_POS))
    F_KEY = wrap(flow_plain(":,}"))
  }

  F_STATE = "after_key"
}

# After a key: a colon brings the member's value, which is null when
# nothing but the next mark follows it; with no colon the member is null.
function flow_after_key(c) {
  if (c == ":") {
    F_POS++
    c = flow_peek()
  }

  if (c == "," || c == "}") {
    write_scalar(F_KEY, "null", "")
    F_STATE = "more"
  } else {
    F_STATE = "value"
  }
}

# More: after a member, a comma brings the next, the closer ends the
# collection, and with none open the flow is done.
function flow_more(c) {
  if (F_DEPTH == 0) {
    F_STATE = "done"
  } else if (c == ",") {
    F_POS++
    F_KEY = ""
    F_STATE = (OPEN_KIND[OPEN] == "map") ? "key" : "value"
  } else if (c == ((OPEN_KIND[OPEN] == "map") ? "}" : "]")) {
    flow_close()
  } else {
    refuse_yaml("a flow collection with no comma between two members")
  }
}

# Reads the flow collection that opens the text, which must be the whole
# of it, under <key>.
function read_flow(key, text, __c) {
  F_TEXT = text
  F_POS = 1
  F_DEPTH = 0
  F_KEY = key
  F_STATE = "value"

  while (F_STATE != "done") {
    __c = flow_peek()

    if (F_STATE == "value") {
      flow_value(__c)
    } else if (F_STATE == "first_value") {
      flow_first_value(__c)
    } else if (F_STATE == "first_key") {
      flow_first_key(__c)
    } else if (F_STATE == "key") {
      flow_key(__c)
    } else if (F_STATE == "after_key") {
      flow_after_key(__c)
    } else {
      flow_more(__c)
    }
  }

  if (flow_peek() != "") {
    refuse_yaml("text after the end of a flow collection")
  }
}
