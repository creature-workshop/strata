# Functions that change a tree that tree.awk read. A program uses them to
# print the document it was given with some values replaced or added. This
# file contains functions only. silt__run loads it ahead of every program
# it runs.
#
# A value is given the way a line writes it after its key: "int=3",
# "str=\"a\"", "bool=true", "null", "list" or "map".

# A new node under a key written as a line writes it, with a type, no
# value and no children. It has no parent until tree_adopt, append_node or
# put_node gives it one.
function new_node(key, type) {
  NODES++
  NODE_KEY[NODES] = key
  NODE_TYPE[NODES] = type
  NODE_VALUE[NODES] = ""
  NODE_LEAF[NODES] = 0
  NODE_FIRST[NODES] = 0
  NODE_NEXT[NODES] = 0
  NODE_COUNT[NODES] = 0

  return NODES
}

# Gives a node a value. The node loses the children it had.
function write_value(node, value, __at) {
  __at = index(value, "=")

  NODE_TYPE[node] = (__at > 0) ? substr(value, 1, __at - 1) : value
  NODE_VALUE[node] = (__at > 0) ? substr(value, __at + 1) : ""
  NODE_LEAF[node] = (__at > 0)
  NODE_FIRST[node] = 0
  NODE_COUNT[node] = 0
}

# The member of a map under a name given as plain text. A map that has no
# such member gets one, a null, after its last member.
function member_or_new(map, name, __node) {
  __node = member(map, name)
  if (__node == 0) {
    __node = new_node(wrap(name), "null")
    tree_adopt(map, __node)
  }

  return __node
}

# The map under a name of a map. A member that is missing or is not a map
# becomes an empty map.
function map_under(map, name, __node) {
  __node = member_or_new(map, name)
  if (NODE_TYPE[__node] != "map") {
    write_value(__node, "map")
  }

  return __node
}

# Puts a value under a name of a map. A member the map has keeps its
# place, and one it does not have is added after the last.
function put(map, name, value) {
  write_value(member_or_new(map, name), value)
}

# Puts what another node holds under a name of a map: its type, its value
# and its children. The children are the other node's own, not copies. No
# node puts a null.
function put_node(map, name, node, __member) {
  __member = member_or_new(map, name)
  if (node == 0) {
    write_value(__member, "null")
    return
  }

  NODE_TYPE[__member] = NODE_TYPE[node]
  NODE_VALUE[__member] = NODE_VALUE[node]
  NODE_LEAF[__member] = NODE_LEAF[node]
  NODE_FIRST[__member] = NODE_FIRST[node]
  NODE_LAST[__member] = NODE_LAST[node]
  NODE_COUNT[__member] = NODE_COUNT[node]
}

# Makes a node the last element of a list, under the next index.
function append_node(list, node) {
  NODE_KEY[node] = NODE_COUNT[list]
  NODE_NEXT[node] = 0
  tree_adopt(list, node)
}

# Adds a text to a list as its last element, a str.
function append_text(list, text, __node) {
  __node = new_node(NODE_COUNT[list], "str")
  NODE_VALUE[__node] = wrap(text)
  NODE_LEAF[__node] = 1
  tree_adopt(list, __node)
}

# A new list of the texts given, each a str.
function list_of_texts(texts, count, __list, __i) {
  __list = new_node("", "list")
  for (__i = 1; __i <= count; __i++) {
    append_text(__list, texts[__i])
  }

  return __list
}
