# Functions that compare two values in the trees that tree.awk read. This
# file contains functions only. silt__run loads it ahead of every program
# it runs.

# Whether two nodes hold the same value. No node and a null are the same.
# Two numbers are the same when they are equal, however they are written.
# Two lists are the same when they have the same values in the same order,
# and two maps when they have the same names with the same values, in any
# order.
function same_value(a, b, __child) {
  if (!is_present(a) || !is_present(b)) {
    return !is_present(a) && !is_present(b)
  }
  if (is_number(a) && is_number(b)) {
    return text_of(a) + 0 == text_of(b) + 0
  }
  if (NODE_TYPE[a] != NODE_TYPE[b] || NODE_COUNT[a] != NODE_COUNT[b]) {
    return 0
  }
  if (NODE_TYPE[a] == "list") {
    return same_elements(a, b)
  }
  if (NODE_TYPE[a] == "map") {
    return same_members(a, b)
  }

  return NODE_VALUE[a] == NODE_VALUE[b]
}

# Whether a node holds a number.
function is_number(node) {
  return NODE_TYPE[node] == "int" || NODE_TYPE[node] == "float"
}

# Whether two lists of one length have the same values in the same order.
function same_elements(a, b, __left, __right) {
  __right = NODE_FIRST[b]
  for (__left = NODE_FIRST[a]; __left != 0; __left = NODE_NEXT[__left]) {
    if (!same_value(__left, __right)) {
      return 0
    }
    __right = NODE_NEXT[__right]
  }

  return 1
}

# Whether two maps of one size have the same names with the same values.
function same_members(a, b, __left, __right) {
  for (__left = NODE_FIRST[a]; __left != 0; __left = NODE_NEXT[__left]) {
    __right = child(b, NODE_KEY[__left])
    if (__right == 0 || !same_value(__left, __right)) {
      return 0
    }
  }

  return 1
}
