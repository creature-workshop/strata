# What a node of a tree is as a JSON value: the name JSON gives its type,
# its text as one line of JSON, the text by which two values are the same
# value, and what a message says of it. Loaded after schema/tree.awk.
#
#   json_type(n)   int=3                 ->  number
#   json_text(n)   0."a":int=1           ->  {"a":1}
#   said(n)        str="x"               ->  x
#   identity(n)    float=1.0, or int=1   ->  1

# The name JSON gives the node's type.
function json_type(node) {
  if (TYPE_OF[node] == "map") {
    return "object"
  }
  if (TYPE_OF[node] == "list") {
    return "array"
  }
  if (TYPE_OF[node] == "str") {
    return "string"
  }
  if (TYPE_OF[node] == "bool") {
    return "boolean"
  }
  if (TYPE_OF[node] == "null") {
    return "null"
  }

  return "number"
}

# Whether the node is a number, an int or a float.
function is_number(node) {
  return TYPE_OF[node] == "int" || TYPE_OF[node] == "float"
}

# The number a node spells.
function number_of(node) {
  return VALUE_OF[node] + 0
}

# The text a str node holds, its escapes decoded.
function text_of(node) {
  return unwrap(VALUE_OF[node])
}

# The members of a map as JSON writes them, with each value spelled by
# json_text, or by identity when <exact> is 0.
function members_text(node, exact, __i, __out, __child) {
  __out = ""

  for (__i = 0; __i < COUNT[node]; __i++) {
    __child = CHILD_AT[node, __i]
    __out = __out (__i > 0 ? "," : "") wrap(NAME_OF[__child]) ":" value_text(__child, exact)
  }

  return "{" __out "}"
}

# The elements of a list as JSON writes them, spelled as members_text
# spells a map's.
function elements_text(node, exact, __i, __out) {
  __out = ""

  for (__i = 0; __i < COUNT[node]; __i++) {
    __out = __out (__i > 0 ? "," : "") value_text(CHILD_AT[node, __i], exact)
  }

  return "[" __out "]"
}

# A number's text: as its line writes it when <exact> is 1, and otherwise
# as the number it stands for, so 1 and 1.0 are one text.
function number_text(node, exact) {
  if (exact) {
    return VALUE_OF[node]
  }

  return sprintf("%.17g", number_of(node))
}

# The node as one line of JSON, a number spelled as number_text says.
function value_text(node, exact) {
  if (TYPE_OF[node] == "map") {
    return members_text(node, exact)
  }
  if (TYPE_OF[node] == "list") {
    return elements_text(node, exact)
  }
  if (TYPE_OF[node] == "str") {
    return wrap(text_of(node))
  }
  if (TYPE_OF[node] == "null") {
    return "null"
  }
  if (is_number(node)) {
    return number_text(node, exact)
  }

  return VALUE_OF[node]
}

# The node as one line of JSON, every number as written.
function json_text(node) {
  return value_text(node, 1)
}

# The text two nodes share exactly when they are the same value: a map in
# the order of its keys, and a number by what it stands for.
function identity(node) {
  return value_text(node, 0)
}

# What a message says of a node: a string's own text, and any other value
# as JSON.
function said(node) {
  if (TYPE_OF[node] == "str") {
    return text_of(node)
  }

  return json_text(node)
}

# How many characters the text holds, a character of several bytes counted
# once whether awk reads bytes or characters.
function chars(text, __i, __count, __byte) {
  __count = 0

  for (__i = 1; __i <= length(text); __i++) {
    __byte = ORD[substr(text, __i, 1)]
    if (__byte < 128 || __byte >= 192) {
      __count++
    }
  }

  return __count
}
