# A YAML document's block structure read into the SILT writer, one line at
# a time and never deeper than the line. The collections open are a stack
# the line is measured against by indentation: a line indented less closes
# what it leaves behind, one indented more fills the slot a key or a dash
# left open, and one at the same indentation is the next member. A line's
# own text is read left to right, a dash that opens a collection on its own
# line making the rest of the line a line of its own. Loaded after
# write.awk, yaml_lines.awk, yaml_scalars.awk, yaml_values.awk,
# yaml_flow.awk and yaml_blocks.awk.
#
#   jobs:              ->  0."jobs":list
#     - name: test         1.0:map
#       needs: []          2."name":str="test"
#                          2."needs":list

# Whether the text is an element of a block sequence.
function is_item(text) {
  return text == "-" || text ~ /^- /
}

# An element's text past its dash.
function item_rest(text) {
  sub(/^-[ ]*/, "", text)
  return text
}

# Whether the text is a mapping's "key: value". When it is, Y_KEY holds the
# key as a JSON string literal and Y_REST what follows its colon.
function is_key(text) {
  if (text ~ /^[\[{]/ || is_item(text)) {
    return 0
  }
  if (text ~ /^\? /) {
    refuse_yaml("a complex key")
  }
  if (text ~ /^["']/) {
    return split_quoted_key(text)
  }

  return split_plain_key(text)
}

# Splits a quoted key off the text, which opens with its quote. Returns
# whether a colon follows the quoted scalar, which is what makes it a key.
function split_quoted_key(text, __end, __after) {
  __end = quote_end(text, 1)
  if (__end == 0) {
    refuse_yaml("a quoted scalar that runs over lines")
  }

  __after = substr(text, __end)
  if (__after !~ /^ *:( |$)/) {
    return 0
  }

  Y_KEY = wrap(unquote(substr(text, 1, __end - 1)))
  sub(/^ *:/, "", __after)
  Y_REST = trim(__after)
  return 1
}

# Splits a plain key off the text at its first ": ", or at a colon that
# ends it.
function split_plain_key(text, __at, __key) {
  __at = index(text, ": ")
  if (__at == 0 && text ~ /:$/) {
    __at = length(text)
  }
  if (__at <= 1) {
    return 0
  }

  __key = rtrim(substr(text, 1, __at - 1))
  refuse_unread(__key)
  if (__key == "<<") {
    refuse_yaml("a merge key")
  }

  Y_KEY = wrap(__key)
  Y_REST = trim(substr(text, __at + 1))
  return 1
}

# Opens a block collection under <key>, its members at <indent>.
function open_block(kind, key, indent) {
  open_collection(kind, key)
  B_INDENT[OPEN] = indent
}

# Leaves the slot of a key or a dash with nothing after it open for the
# lines that follow, and steps past the line.
function leave_slot(key, indent) {
  PENDING = 1
  PENDING_KEY = key
  PENDING_INDENT = indent
  Y_POS++
}

# Fills the slot left open with the line the reader stands on, indented
# past it: a dash opens a list there, a key a map, and anything else is the
# slot's scalar, read off the line.
function fill_slot(indent, text) {
  if (is_item(text)) {
    open_block("list", PENDING_KEY, indent)
  } else if (is_key(text)) {
    open_block("map", PENDING_KEY, indent)
  } else {
    write_value(PENDING_KEY, text, PENDING_INDENT)
    CONSUMED = 1
  }
}

# Settles the slot left open against the line the reader stands on: filled
# by a line indented past it, or by a dash at a map key's own indentation,
# which YAML allows; null otherwise.
function resolve_pending(indent, text) {
  PENDING = 0
  CONSUMED = 0

  if (indent > PENDING_INDENT) {
    fill_slot(indent, text)
  } else if (indent == PENDING_INDENT && is_item(text) && OPEN_KIND[OPEN] == "map") {
    open_block("list", PENDING_KEY, indent)
  } else {
    write_scalar(PENDING_KEY, "null", "")
  }
}

# Closes every block collection indented past the line, and refuses a line
# indented past the one left open, or one after a scalar document.
function close_blocks_above(indent) {
  while (OPEN > 0 && B_INDENT[OPEN] > indent) {
    close_collection()
  }

  if (OPEN == 0 || B_INDENT[OPEN] < indent) {
    refuse_yaml("out of place in the tree")
  }
}

# The line's dash must be the next element of the list open at its
# indentation.
function require_list_at(indent) {
  if (OPEN == 0 || OPEN_KIND[OPEN] != "list" || B_INDENT[OPEN] != indent) {
    refuse_yaml("out of place in the tree")
  }
}

# The line's key must be the next member of the map open at its
# indentation; a list open at the same indentation, one that sat at its
# key's own, is closed first.
function require_map_at(indent) {
  if (OPEN > 1 && OPEN_KIND[OPEN] == "list" && B_INDENT[OPEN] == indent && B_INDENT[OPEN - 1] == indent) {
    close_collection()
  }

  if (OPEN == 0 || OPEN_KIND[OPEN] != "map" || B_INDENT[OPEN] != indent) {
    refuse_yaml("out of place in the tree")
  }
}

# Writes the value written on the rest of one line under <key>, a block
# scalar under a node indented by <parent> among them, and steps past it.
function write_value(key, text, parent) {
  if (is_block_header(text)) {
    write_block(key, text, parent)
    return
  }

  write_inline(key, text)
  Y_POS++
}

# Whether an element's text past its dash opens a collection on the dash's
# own line: another dash, or a key.
function opens_compact(rest) {
  return rest != "" && !is_block_header(rest) && (is_item(rest) || is_key(rest))
}

# Reads an element that is a value of its own: a dash with nothing after it
# leaves a slot open, and anything else is the element's value.
function read_item(indent, rest) {
  if (rest == "") {
    leave_slot("", indent)
    return
  }

  write_value("", rest, indent)
}

# Reads the member whose key is_key just split off: a key with nothing
# after its colon leaves a slot open, and anything else is the member's
# value.
function read_member(indent) {
  if (Y_REST == "") {
    leave_slot(Y_KEY, indent)
    return
  }

  write_value(Y_KEY, Y_REST, indent)
}

# Reads the node that begins on the line the reader stands on, at <indent>.
# A dash whose rest opens a collection is read as if that rest began a line
# of its own, indented to where it sits.
function read_node(indent, text, __rest) {
  while (is_item(text)) {
    require_list_at(indent)
    __rest = item_rest(text)

    if (!opens_compact(__rest)) {
      read_item(indent, __rest)
      return
    }

    indent = indent + length(text) - length(__rest)
    text = __rest
    open_block(is_item(text) ? "list" : "map", "", indent)
  }

  if (!is_key(text)) {
    refuse_yaml("out of place in the tree")
  }

  require_map_at(indent)
  read_member(indent)
}

# Reads the line the reader stands on, which holds something: it settles
# the slot left open, closes what it leaves behind, and is read as a node.
function read_content_line(__indent, __text) {
  __indent = Y_INDENT[Y_POS]
  __text = Y_TEXT[Y_POS]

  if (__text ~ /^\t/) {
    refuse_yaml("a tab in the indentation")
  }

  if (PENDING) {
    resolve_pending(__indent, __text)
    if (CONSUMED) {
      return
    }
  }

  close_blocks_above(__indent)
  read_node(__indent, __text)
}

# Steps over the "---" that may open the document, refusing a directive.
function skip_document_start() {
  skip_blank()

  if (Y_POS <= Y_N && Y_TEXT[Y_POS] ~ /^%/) {
    refuse_yaml("a directive")
  }
  if (Y_POS <= Y_N && Y_TEXT[Y_POS] == "---") {
    Y_POS++
  }
}

# Whether the line the reader stands on ends the document: "..." or a
# second document's "---".
function ends_document(text) {
  return text == "..." || text ~ /^---( |$)/
}

# Refuses whatever is left once the document's one value has been read,
# past a "..." that ends it.
function refuse_leftover() {
  if (!at_end() && Y_TEXT[Y_POS] == "...") {
    Y_POS++
  }
  if (at_end()) {
    return
  }

  refuse_yaml(Y_TEXT[Y_POS] ~ /^---/ ? "a second document" : "out of place in the tree")
}

# Settles the slot still open once the lines are read: an empty document is
# null, and so is a key or a dash nothing followed. Closes every block.
function finish_tree() {
  if (PENDING) {
    write_scalar(PENDING_KEY, "null", "")
  }

  while (OPEN > 0) {
    close_collection()
  }
}

# Reads the whole document kept with keep_line into the writer.
function read_tree() {
  read_lines()
  skip_document_start()
  PENDING = 1
  PENDING_KEY = ""
  PENDING_INDENT = -1

  while (!at_end() && !ends_document(Y_TEXT[Y_POS])) {
    read_content_line()
  }

  finish_tree()
  refuse_leftover()
}
