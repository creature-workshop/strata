# The two documents of a validation as trees, read through their JSON twins:
# the document on stdin is document 1, the value, and the one in SILT_SPILL
# document 2, the schema. Each is put in canonical order first, so a map's
# members are met in the order of their keys whatever order they were
# written in. A time is the string JSON would carry, and a float JSON cannot
# spell, inf, -inf or nan, is the map ADR.20 gives it. A type JSON has no
# spelling for is refused. It holds functions alone. Loaded after lines.awk
# and order.awk.
#
#   ROOT[doc]          the node a document's value is
#   TYPE_OF[n]         map, list, str, int, float, bool or null
#   VALUE_OF[n]        a leaf's value as its line writes it
#   NAME_OF[n]         a member's key as text, or an element's index
#   COUNT[n]           how many members a collection holds
#   CHILD_AT[n, i]     its member at place i, from 0
#   CHILD_BY[n, name]  its member under a key or an index

# A node of its own, under no collection yet.
function new_node(type, value) {
  NODES++
  TYPE_OF[NODES] = type
  VALUE_OF[NODES] = value
  COUNT[NODES] = 0

  return NODES
}

# Puts a node under a collection, at the next place, by its name. A map
# that holds a key twice answers a lookup with the first.
function add_child(parent, name, node) {
  NAME_OF[node] = name
  CHILD_AT[parent, COUNT[parent]] = node
  COUNT[parent]++

  if (!((parent, name) in CHILD_BY)) {
    CHILD_BY[parent, name] = node
  }
}

# The map ADR.20 gives a float JSON cannot spell, as a node.
function spelled_float(spelling, __node) {
  __node = new_node("map", "")
  add_child(__node, "format", new_node("str", "\"strata\""))
  add_child(__node, "spelling", new_node("str", "\"" spelling "\""))

  return __node
}

# The node of the line parse() read last. Refuses a type JSON has no
# spelling for, naming the line.
function node_of_line(line) {
  if (TYPE == "time-rfc3339-utc") {
    return new_node("str", "\"" VALUE "\"")
  }
  if (TYPE == "float" && VALUE ~ /^(-?inf|nan)$/) {
    return spelled_float(VALUE)
  }
  if (TYPE !~ /^(map|list|str|int|float|bool|null)$/) {
    refuse("a type JSON has no spelling for: " line)
  }

  return new_node(TYPE, VALUE)
}

# Places the line parse() read last in the tree of the document: a keyless
# line is the root itself, and any other a member of the collection open
# one depth up, the root at depth 0. Refuses a line deeper than the one
# before it could hold.
function place_line(doc, line, __node, __depth, __name) {
  __depth = DEPTH
  __name = is_name(KEY) ? unwrap(KEY) : KEY

  if (KEY == "") {
    ROOT[doc] = node_of_line(line)
    return
  }
  if (__depth > DEEPEST + 1) {
    refuse("a line deeper than the line above it holds: " line)
  }
  if (ROOT[doc] == 0) {
    ROOT[doc] = new_node(is_name(KEY) ? "map" : "list", "")
  }

  __node = node_of_line(line)
  add_child((__depth == 0) ? ROOT[doc] : OPEN[__depth - 1], __name, __node)
  OPEN[__depth] = __node
  DEEPEST = __depth
}

# Builds the tree of a document from the lines order.awk holds, in canonical
# order, and empties them for the next document.
function build_tree(doc, __k) {
  ROOT[doc] = 0
  DEEPEST = -1
  sort_lines()

  for (__k = 1; __k <= LINES; __k++) {
    parse(LINE[ORDER[__k]])
    place_line(doc, LINE[ORDER[__k]])
  }

  LINES = 0
}

# Reads the document in the spill file into order.awk's lines.
function take_spill(__line) {
  while ((getline __line < ENVIRON["SILT_SPILL"]) > 0) {
    take(__line)
  }

  close(ENVIRON["SILT_SPILL"])
}

# Whether a collection holds a member under the name.
function has(node, name) {
  return (node, name) in CHILD_BY
}

# The member of a collection under the name; asked for only where has()
# says there is one.
function member(node, name) {
  return CHILD_BY[node, name]
}
