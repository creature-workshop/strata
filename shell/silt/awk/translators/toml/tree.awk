# The tree a TOML document builds, held until the text is read, since a
# table header may name a table from anywhere in the document, and the
# rules by which TOML lets a node be added to. A table defined by its
# header takes pairs from its body and sub-tables from later headers, once;
# a table a header's path passes through is implicit until its own header
# comes; a table a dotted key creates is open to more dotted keys until its
# body ends and closed after, though a header may still put a new sub-table
# beneath it; and an inline table, an array and a value take nothing more.
# Once the text is read the tree is walked once into the SILT writer.
# Loaded after awk/lines.awk, order.awk and translators/write.awk, and
# text.awk beside this one.
#
#   N_KIND[n]                  table, array or scalar
#   N_STATE[n]                 a table's: defined, implicit, dotted, closed
#                              or inline; an array's: tables or static
#   N_TYPE[n], N_VALUE[n]      a scalar's SILT type and value
#   N_COUNT[n], N_CHILD[n, i]  the children, in the document's order
#   N_KEY[n, i], N_AT[n, key]  a table's keys, and its child under one

# A new node of <kind>, with no children.
function new_node(kind) {
  NODES++
  N_KIND[NODES] = kind
  N_COUNT[NODES] = 0

  return NODES
}

# A scalar node with its SILT type and value.
function scalar_node(type, value, __node) {
  __node = new_node("scalar")
  N_TYPE[__node] = type
  N_VALUE[__node] = value

  return __node
}

# The map ADR.20 gives a spelling Strata cannot carry, as an inline table:
# the format, the spelling, and the value in ADR.20's form where there is
# one.
function spelling_node(spelling, value_type, value, __node) {
  __node = new_node("table")
  N_STATE[__node] = "inline"
  add_child(__node, "format", scalar_node("str", "\"toml\""))
  add_child(__node, "spelling", scalar_node("str", wrap(spelling)))

  if (value_type != "") {
    add_child(__node, "value", scalar_node(value_type, value))
  }

  return __node
}

# Puts <node> under <key> in <table>. Refuses a key the table holds.
function add_child(table, key, node) {
  if ((table, key) in N_AT) {
    refuse_toml("a key its table already holds: " key)
  }

  N_COUNT[table]++
  N_CHILD[table, N_COUNT[table]] = node
  N_KEY[table, N_COUNT[table]] = key
  N_AT[table, key] = node
}

# Appends <node> to <array>.
function add_element(array, node) {
  N_COUNT[array]++
  N_CHILD[array, N_COUNT[array]] = node
}

# Whether the child under <key> of <table> is a table in <state>.
function is_table_in(table, key, state) {
  return N_KIND[N_AT[table, key]] == "table" && N_STATE[N_AT[table, key]] == state
}

# Whether the child under <key> of <table> is an array of tables.
function is_array_of_tables(table, key) {
  return N_KIND[N_AT[table, key]] == "array" && N_STATE[N_AT[table, key]] == "tables"
}

# A new table under <key> in <table>, in <state>.
function new_table(table, key, state, __node) {
  __node = new_node("table")
  N_STATE[__node] = state
  add_child(table, key, __node)

  return __node
}

# The table a header's path names under <key> of <table>, on the way to
# the path's last segment: a table of any state but inline, an array of
# tables at its last element, or a new table, implicit until its own header
# comes. Refuses an inline table, a static array and a value.
function descend_header(table, key) {
  if (!((table, key) in N_AT)) {
    return new_table(table, key, "implicit")
  }
  if (is_array_of_tables(table, key)) {
    return N_CHILD[N_AT[table, key], N_COUNT[N_AT[table, key]]]
  }
  if (N_KIND[N_AT[table, key]] == "table" && N_STATE[N_AT[table, key]] != "inline") {
    return N_AT[table, key]
  }

  refuse_toml("a table header through " key ", which holds a value")
}

# The table a header defines under <key> of <table>: a new one, or the one
# an earlier header's path made implicit. Refuses a table defined already,
# one a dotted key created, an inline table, an array and a value.
function define_table(table, key) {
  if (!((table, key) in N_AT)) {
    return new_table(table, key, "defined")
  }
  if (is_table_in(table, key, "implicit")) {
    N_STATE[N_AT[table, key]] = "defined"
    return N_AT[table, key]
  }

  refuse_toml("a table header for " what_holds(table, key) ": " key)
}

# The new table an array-of-tables header appends under <key> of <table>,
# the array created when it is new. Refuses a static array, a table and a
# value.
function append_table(table, key, __array, __element) {
  if (!((table, key) in N_AT)) {
    __array = new_node("array")
    N_STATE[__array] = "tables"
    add_child(table, key, __array)
  } else if (is_array_of_tables(table, key)) {
    __array = N_AT[table, key]
  } else {
    refuse_toml("an array-of-tables header for " what_holds(table, key) ": " key)
  }

  __element = new_node("table")
  N_STATE[__element] = "defined"
  add_element(__array, __element)

  return __element
}

# The table a dotted key's segment names under <key> of <table>, on the way
# to the key's last segment: a table open to dotted keys, one an earlier
# header's path made implicit, opened, or a new one, open until the body
# ends. Refuses a table defined by its header, one a dotted key created in
# an earlier body, an inline table, an array and a value.
function descend_dotted(table, key) {
  if (!((table, key) in N_AT)) {
    return open_dotted(new_table(table, key, "dotted"))
  }
  if (is_table_in(table, key, "implicit") || is_table_in(table, key, "dotted")) {
    return open_dotted(N_AT[table, key])
  }

  refuse_toml("a dotted key through " what_holds(table, key) ": " key)
}

# Opens a table to the dotted keys of the body being read, until it ends.
function open_dotted(table) {
  N_STATE[table] = "dotted"
  DOTTED[++DOTTED_N] = table

  return table
}

# Closes the tables the body being read opened to dotted keys.
function close_dotted(__i) {
  for (__i = 1; __i <= DOTTED_N; __i++) {
    N_STATE[DOTTED[__i]] = "closed"
  }

  DOTTED_N = 0
}

# What the child under <key> of <table> is, for a refusal.
function what_holds(table, key, __node) {
  __node = N_AT[table, key]

  if (N_KIND[__node] == "table") {
    return table_words(N_STATE[__node])
  }
  if (is_array_of_tables(table, key)) {
    return "an array of tables"
  }

  return "a key that holds a value"
}

# A table's state in words, for a refusal.
function table_words(state) {
  if (state == "defined") {
    return "a table defined already"
  }
  if (state == "inline") {
    return "an inline table"
  }
  if (state == "implicit") {
    return "a table another header's path made"
  }

  return "a table a dotted key defined"
}

# Writes the tree under <node> into the SILT writer as the member <key> of
# the collection open: a scalar as its line, a table as a map and an array
# as a list, each child after it in the document's order, the writer
# putting every map in canonical order.
function emit(node, key, __i) {
  if (N_KIND[node] == "scalar") {
    write_scalar(key, N_TYPE[node], N_VALUE[node])
    return
  }

  open_collection((N_KIND[node] == "table") ? "map" : "list", key)
  for (__i = 1; __i <= N_COUNT[node]; __i++) {
    emit(N_CHILD[node, __i], child_key(node, __i))
  }
  close_collection()
}

# The key child i of <node> is written under: its key as a JSON string
# literal under a table, and nothing under an array, whose indices are the
# writer's.
function child_key(node, i) {
  return (N_KIND[node] == "table") ? wrap(N_KEY[node, i]) : ""
}
