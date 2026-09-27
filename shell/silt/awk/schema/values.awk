# Functions that read a tree node as a JSON value: its JSON type name, its
# JSON text, a key for comparing two values, and the text used for it in
# error messages. Load after schema/tree.awk.
#
#   json_type(n)        int=3                 ->  number
#   json_text(n)        0."a":int=1           ->  {"a":1}
#   message_text(n)     str="x"               ->  x
#   comparison_key(n)   float=1.0, or int=1   ->  1

# Returns the JSON type name of a node: object, array, string, boolean,
# null or number.
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

# Returns 1 if the node is an int or a float.
function is_number(node) {
  return TYPE_OF[node] == "int" || TYPE_OF[node] == "float"
}

# Returns the numeric value of a number node.
function number_of(node) {
  return VALUE_OF[node] + 0
}

# Returns the text of a string node, with escape sequences decoded.
function text_of(node) {
  return unwrap(VALUE_OF[node])
}

# Returns a map node as JSON text. If exact is 1, numbers are written as
# they appear in the document. If exact is 0, they are normalised (see
# number_text).
function members_text(node, exact, __i, __out, __child) {
  __out = ""

  for (__i = 0; __i < COUNT[node]; __i++) {
    __child = CHILD_AT[node, __i]
    __out = __out (__i > 0 ? "," : "") wrap(NAME_OF[__child]) ":" value_text(__child, exact)
  }

  return "{" __out "}"
}

# Returns a list node as JSON text. The exact argument works as it does in
# members_text.
function elements_text(node, exact, __i, __out) {
  __out = ""

  for (__i = 0; __i < COUNT[node]; __i++) {
    __out = __out (__i > 0 ? "," : "") value_text(CHILD_AT[node, __i], exact)
  }

  return "[" __out "]"
}

# Returns the text of a number node. If exact is 1, this is the text as
# written in the document. If exact is 0, the number is normalised, so that
# 1 and 1.0 produce the same text.
function number_text(node, exact) {
  if (exact) {
    return VALUE_OF[node]
  }

  return sprintf("%.17g", number_of(node))
}

# Returns any node as one line of JSON text. The exact argument works as it
# does in members_text.
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

# Returns a node as one line of JSON text, with numbers as written in the
# document.
function json_text(node) {
  return value_text(node, 1)
}

# Returns a string that is the same for two nodes exactly when they are
# equal as JSON values. Map keys are in sorted order and numbers are
# normalised, so {"a":1,"b":2} equals {"b":2,"a":1}, and 1 equals 1.0.
function comparison_key(node) {
  return value_text(node, 0)
}

# Returns the text used for a node in an error message: the text of a
# string without quotes, and JSON text for any other value. This matches how
# the jq validator formats values.
function message_text(node) {
  if (TYPE_OF[node] == "str") {
    return text_of(node)
  }

  return json_text(node)
}

# Returns the number of characters in the text. A multi-byte UTF-8 character
# counts as one, whether this awk counts bytes or characters.
function character_count(text, __i, __count, __byte) {
  __count = 0

  for (__i = 1; __i <= length(text); __i++) {
    __byte = ORD[substr(text, __i, 1)]
    if (__byte < 128 || __byte >= 192) {
      __count++
    }
  }

  return __count
}
