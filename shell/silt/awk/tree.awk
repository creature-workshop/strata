# The documents an awk program reads, as trees of nodes, for the programs
# that silt__run runs. It holds functions alone. Loaded after lines.awk,
# whose parse() reads each line.
#
# A program builds the tree of the document it was given like this:
#
#   BEGIN { ROOT = tree_open() }
#   { tree_line($0) }
#   END { ... read the tree under ROOT, and print a document ... }
#
# A document given with --with arrives ahead of the main one. The program
# reads each in BEGIN, in the order given, before it opens the main tree:
#
#   BEGIN { OTHER = tree_ahead(); ROOT = tree_open() }
#
# A node is a number, and 0 is no node, so a member that is missing reads
# as 0 and every function here accepts it.
#
#   NODES            how many nodes there are
#   NODE_KEY[n]      the key of node n as its line writes it: a quoted
#                    literal under a map, an index under a list, and empty
#                    for the root of a document
#   NODE_TYPE[n]     its type: map, list, null, str, int, float, bool
#   NODE_VALUE[n]    its value as its line writes it, when it has one
#   NODE_LEAF[n]     1 when the node has a value
#   NODE_FIRST[n]    its first child, 0 when it has none
#   NODE_NEXT[n]     the next child of its parent, 0 when it is the last
#   NODE_COUNT[n]    how many children it has

# Opens a new document and returns its root. The lines given to tree_line
# after this belong to it.
function tree_open() {
  NODES++
  OPEN_ROOT = NODES
  NODE_KEY[OPEN_ROOT] = ""
  NODE_TYPE[OPEN_ROOT] = ""
  NODE_FIRST[OPEN_ROOT] = 0
  NODE_COUNT[OPEN_ROOT] = 0

  return OPEN_ROOT
}

# Adds one line to the open document. A keyless line is the root itself: a
# scalar, or a map or a list with no member. Any other line is a node under
# the node last read one level up.
function tree_line(line, __node, __parent) {
  parse(line)

  if (DEPTH == 0 && KEY == "") {
    NODE_TYPE[OPEN_ROOT] = TYPE
    NODE_VALUE[OPEN_ROOT] = VALUE
    NODE_LEAF[OPEN_ROOT] = LEAF
    return
  }

  if (DEPTH == 0 && NODE_TYPE[OPEN_ROOT] == "") {
    NODE_TYPE[OPEN_ROOT] = is_name(KEY) ? "map" : "list"
  }

  NODES++
  __node = NODES
  NODE_KEY[__node] = KEY
  NODE_TYPE[__node] = TYPE
  NODE_VALUE[__node] = VALUE
  NODE_LEAF[__node] = LEAF
  NODE_FIRST[__node] = 0
  NODE_NEXT[__node] = 0
  NODE_COUNT[__node] = 0

  __parent = (DEPTH == 0) ? OPEN_ROOT : OPEN_AT[DEPTH - 1]
  tree_adopt(__parent, __node)
  OPEN_AT[DEPTH] = __node
}

# Makes a node the last child of a parent.
function tree_adopt(parent, node) {
  if (NODE_FIRST[parent] == 0) {
    NODE_FIRST[parent] = node
  } else {
    NODE_NEXT[NODE_LAST[parent]] = node
  }

  NODE_LAST[parent] = node
  NODE_COUNT[parent]++
}

# Reads the next document that was given with --with, and returns its
# root. A program calls it from BEGIN, once for each such document, in
# their order.
function tree_ahead(__root, __i) {
  read_ahead()
  __root = tree_open()

  for (__i = 1; __i <= AHEADS; __i++) {
    tree_line(AHEAD[__i])
  }

  return __root
}

# The value of the argument given as --arg <name> <value>.
function arg(name) {
  return ENVIRON["SILT_ARG_" name]
}

# The child of a node under a key written as a line writes it: a quoted
# literal or an index. 0 when the node has no such child.
function child(node, key, __at) {
  for (__at = NODE_FIRST[node]; __at != 0; __at = NODE_NEXT[__at]) {
    if (NODE_KEY[__at] == key) {
      return __at
    }
  }

  return 0
}

# The member of a map under a name given as plain text. 0 when the map has
# no such member.
function member(node, name) {
  return child(node, wrap(name))
}

# The name of a node as plain text: a map's key without its quotes, or a
# list's index.
function name_of(node) {
  return is_name(NODE_KEY[node]) ? unwrap(NODE_KEY[node]) : NODE_KEY[node]
}

# Whether a node holds a value that is not a null. No node holds none.
function is_present(node) {
  return node != 0 && NODE_TYPE[node] != "null"
}

# The text of a node, the way silt__string reads it: a str without its
# quotes, a number or a bool as written, a null as the word null, and the
# empty string for no node, a map or a list.
function text_of(node) {
  if (node == 0 || NODE_TYPE[node] == "map" || NODE_TYPE[node] == "list") {
    return ""
  }
  if (NODE_TYPE[node] == "null") {
    return "null"
  }
  if (NODE_TYPE[node] == "str") {
    return unwrap(NODE_VALUE[node])
  }

  return NODE_VALUE[node]
}

# The text of a node, or a default where the node is missing or a null.
function text_or(node, fallback) {
  return is_present(node) ? text_of(node) : fallback
}

# What a node writes after its key on a line: its type, and its value when
# it has one. No node writes a null.
function written(node) {
  if (node == 0) {
    return "null"
  }

  return NODE_LEAF[node] ? NODE_TYPE[node] "=" NODE_VALUE[node] : NODE_TYPE[node]
}

# Prints a node and everything under it at a depth and under a key, both of
# the caller's choosing, so a program can put a value it read under another
# name. No node prints as a null.
function print_node(node, depth, key, __at) {
  print depth "." key ":" written(node)

  for (__at = NODE_FIRST[node]; __at != 0; __at = NODE_NEXT[__at]) {
    print_node(__at, depth + 1, NODE_KEY[__at])
  }
}

# Prints a node as a document of its own: a scalar or an empty map or list
# as one keyless line, and a map or a list with members as those members at
# depth 0. No node prints as the null document.
function print_document(node, __at) {
  if (NODE_FIRST[node] == 0) {
    print "0.:" written(node)
    return
  }

  for (__at = NODE_FIRST[node]; __at != 0; __at = NODE_NEXT[__at]) {
    print_node(__at, 0, NODE_KEY[__at])
  }
}

# Prints a str line: the text given, under a name given as plain text.
function print_str(depth, name, text) {
  print depth "." wrap(name) ":str=" wrap(text)
}

# Prints the line that opens a map or a list under a key written as a line
# writes it.
function print_open(depth, key, type) {
  print depth "." key ":" type
}
