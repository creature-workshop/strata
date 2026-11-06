# Loads the documents used in validation into trees. Document 1 is the
# value, read from stdin. Document 2 is the schema, and documents 3 and
# above are the other schema documents that the schema refers to, under the
# keys SILT_DOCUMENTS lists; the shell sends them ahead of the value on
# stdin, in that order.
#
# Each document is sorted into canonical order before the tree is built, so
# the members of a map are always visited in key order, whatever order they
# were written in.
#
# Values are loaded as the JSON they translate to. A time becomes a string.
# A float of inf, -inf or nan becomes the map that ADR.20@strata defines for
# it. A type that has no JSON equivalent is an error.
#
# This file contains functions only. Load after lines.awk and order.awk.
#
#   ROOT[doc]          the root node of a document
#   TYPE_OF[n]         map, list, str, int, float, bool or null
#   VALUE_OF[n]        the value of a leaf node, as written in its line
#   NAME_OF[n]         a member's key as text, or an element's index
#   COUNT[n]           the number of children of a map or list
#   CHILD_AT[n, i]     the child at position i, counting from 0
#   CHILD_BY[n, name]  the child with the given key or index

# Creates a node with no parent and returns its id.
function new_node(type, value) {
  NODES++
  TYPE_OF[NODES] = type
  VALUE_OF[NODES] = value
  COUNT[NODES] = 0

  return NODES
}

# Adds a node to a map or list as its last child. If a map contains the same
# key twice, lookups by key return the first one.
function add_child(parent, name, node) {
  NAME_OF[node] = name
  CHILD_AT[parent, COUNT[parent]] = node
  COUNT[parent]++

  if (!((parent, name) in CHILD_BY)) {
    CHILD_BY[parent, name] = node
  }
}

# Creates the map node that ADR.20@strata defines for a float JSON cannot
# represent (inf, -inf or nan), and returns its id.
function non_finite_float_node(spelling, __node) {
  __node = new_node("map", "")
  add_child(__node, "format", new_node("str", "\"strata\""))
  add_child(__node, "spelling", new_node("str", "\"" spelling "\""))

  return __node
}

# Creates a node for the line that parse() read last and returns its id.
# Exits with an error if the line's type has no JSON equivalent.
function node_of_line(line) {
  if (TYPE == "time-rfc3339-utc") {
    return new_node("str", "\"" VALUE "\"")
  }
  if (TYPE == "float" && VALUE ~ /^(-?inf|nan)$/) {
    return non_finite_float_node(VALUE)
  }
  if (TYPE !~ /^(map|list|str|int|float|bool|null)$/) {
    refuse("type cannot be represented in JSON: " line)
  }

  return new_node(TYPE, VALUE)
}

# Adds the line that parse() read last to the tree of the given document. A
# line with no key is the root. Any other line becomes a child of the most
# recent node one level up, or of the root at depth 0. Exits with an error
# if the line is nested more than one level deeper than the line before it.
function place_line(doc, line, __node, __depth, __name) {
  __depth = DEPTH
  __name = is_name(KEY) ? unwrap(KEY) : KEY

  if (KEY == "") {
    ROOT[doc] = node_of_line(line)
    return
  }
  if (__depth > DEEPEST + 1) {
    refuse("line is nested more than one level deeper than the line before it: " line)
  }
  if (ROOT[doc] == 0) {
    ROOT[doc] = new_node(is_name(KEY) ? "map" : "list", "")
  }

  __node = node_of_line(line)
  add_child((__depth == 0) ? ROOT[doc] : OPEN[__depth - 1], __name, __node)
  OPEN[__depth] = __node
  DEEPEST = __depth
}

# Builds the tree of a document from the lines stored by order.awk, in
# canonical order, then clears the stored lines so the next document can be
# read.
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

# Holds the schema and the other schema documents, sent ahead of the value
# on stdin in that order, as HELD[doc, i] with HELD_LINES[doc] lines each,
# from BEGIN. The schema is document 2; the others are numbered on from 3,
# under the keys SILT_DOCUMENTS lists, one on each line in the same order.
# build_schema_trees builds their trees from END, after the value's.
#
#   KEY_OF_DOC[doc]   the key of a document; empty for the schema itself
#   DOC_BY_KEY[key]   the number of the document with that key
#   DOCS              the number of the last document
function hold_schema_documents(__key, __count, __i) {
  DOCS = 2
  KEY_OF_DOC[2] = ""
  hold_ahead(2)

  if (ENVIRON["SILT_DOCUMENTS"] == "") {
    return
  }

  __count = split(ENVIRON["SILT_DOCUMENTS"], __key, "\n")
  for (__i = 1; __i < __count; __i++) {
    DOCS++
    KEY_OF_DOC[DOCS] = __key[__i]
    DOC_BY_KEY[__key[__i]] = DOCS
    hold_ahead(DOCS)
  }
}

# Reads the next document sent ahead and holds its lines under doc.
function hold_ahead(doc, __i) {
  read_ahead()
  HELD_LINES[doc] = AHEADS

  for (__i = 1; __i <= AHEADS; __i++) {
    HELD[doc, __i] = AHEAD[__i]
  }
}

# Builds the trees of the schema and the other schema documents from the
# lines held for each, in order, each taken through order.awk as the
# value's lines were.
function build_schema_trees(__doc) {
  for (__doc = 2; __doc <= DOCS; __doc++) {
    build_held(__doc)
  }
}

# Builds the tree of one held document.
function build_held(doc, __i) {
  for (__i = 1; __i <= HELD_LINES[doc]; __i++) {
    take(HELD[doc, __i])
  }

  build_tree(doc)
}

# Returns 1 if the map or list has a child with the given key or index.
function has(node, name) {
  return (node, name) in CHILD_BY
}

# Returns the child with the given key or index. Call has() first: the
# result is undefined if there is no such child.
function member(node, name) {
  return CHILD_BY[node, name]
}
