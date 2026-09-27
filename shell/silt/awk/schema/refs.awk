# Resolves a schema's $ref. Only references within the schema document are
# supported: the part after "#" is a JSON pointer, resolved from the root of
# the schema.
#
# These cases are validation errors, not program errors:
#
#   - a reference to another document
#   - a pointer that does not lead to a schema
#   - a circular reference, where following references leads back to a
#     schema already visited for the same value
#
# Load after schema/keywords.awk.
#
#   "#/$defs/name"   ->  the member "name" of the member "$defs" of the root

# Decodes one JSON pointer token: ~1 becomes a slash and ~0 becomes a tilde.
function unescape_token(token) {
  gsub(/~1/, "/", token)
  gsub(/~0/, "~", token)

  return token
}

# Returns the child of a node that a pointer token refers to, or 0 if there
# is none. A map is looked up by key. A list is looked up by index, and the
# token must be all digits.
function child_for_token(node, name) {
  if (TYPE_OF[node] == "list" && name !~ /^[0-9]+$/) {
    return 0
  }
  if (TYPE_OF[node] == "list") {
    name = name + 0
  }

  return has(node, name) ? member(node, name) : 0
}

# Returns the node that a JSON pointer refers to, starting from the root of
# the schema. Returns 0 if any step of the pointer does not exist.
function resolve_pointer(fragment, __token, __count, __i, __node) {
  __node = ROOT[2]
  sub(/^\//, "", fragment)
  if (fragment == "") {
    return __node
  }

  __count = split(fragment, __token, "/")
  for (__i = 1; __i <= __count && __node != 0; __i++) {
    __node = child_for_token(__node, unescape_token(__token[__i]))
  }

  return __node
}

# Returns 1 if the node can be used as a schema, which means it is a map or
# a bool.
function is_schema(node) {
  return node != 0 && (TYPE_OF[node] == "map" || TYPE_OF[node] == "bool")
}

# Validates the value against the schema that a reference points to, or
# records an error if the reference cannot be followed.
#
#   ref    The reference as written, for example "#/$defs/name".
#   seen   The pointers already followed for this value, each written as
#          "\n<pointer>\n" with the pointer between "<" and ">". Used to
#          detect circular references. The brackets keep two entries side by
#          side from looking like the empty pointer, which is the root.
function follow_ref(ref, value, path, seen, __at, __fragment, __target) {
  __at = index(ref, "#")
  __fragment = (__at > 0) ? substr(ref, __at + 1) : ""

  if (__at != 1 && ref != "") {
    add_error(path, "unresolvable $ref '" ref "'")
    return
  }

  __target = resolve_pointer(__fragment)
  if (!is_schema(__target)) {
    add_error(path, "$ref '" ref "' does not resolve to a schema")
  } else if (index(seen, "\n<" __fragment ">\n") > 0) {
    add_error(path, "circular $ref '" ref "'")
  } else {
    validate(__target, value, path, seen "\n<" __fragment ">\n")
  }
}

# Handles the $ref keyword: validates the value against the referenced
# schema.
function check_ref(schema, value, path, seen) {
  if (!has(schema, "$ref")) {
    return
  }
  if (TYPE_OF[member(schema, "$ref")] != "str") {
    add_error(path, "$ref must be a string")
    return
  }

  follow_ref(text_of(member(schema, "$ref")), value, path, seen)
}
