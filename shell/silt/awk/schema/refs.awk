# A schema's $ref, followed within the schema's own document: the fragment
# is a JSON pointer walked from the schema's root. A reference to another
# document is an error against the value, as is a fragment that names no
# schema, and a chain of references that comes back to a schema it has
# followed at the same place in the value. Loaded after schema/keywords.awk.
#
#   "#/$defs/name"   ->  the member name of the member $defs of the root

# A pointer's token as the name it stands for, ~1 a slash and ~0 a tilde.
function token_name(token) {
  gsub(/~1/, "/", token)
  gsub(/~0/, "~", token)

  return token
}

# The member a token names under a node, or 0 where the node holds none: a
# map by its key, and a list by an index of bare digits.
function step(node, name) {
  if (TYPE_OF[node] == "list" && name !~ /^[0-9]+$/) {
    return 0
  }
  if (TYPE_OF[node] == "list") {
    name = name + 0
  }

  return has(node, name) ? member(node, name) : 0
}

# The node a fragment points at from the schema's root, or 0 when a step of
# it names nothing.
function pointed_at(fragment, __token, __count, __i, __node) {
  __node = ROOT[2]
  sub(/^\//, "", fragment)
  if (fragment == "") {
    return __node
  }

  __count = split(fragment, __token, "/")
  for (__i = 1; __i <= __count && __node != 0; __i++) {
    __node = step(__node, token_name(__token[__i]))
  }

  return __node
}

# Whether a node is a schema, a map or a bool.
function is_schema(node) {
  return node != 0 && (TYPE_OF[node] == "map" || TYPE_OF[node] == "bool")
}

# Follows a reference written in full: its document before the "#" and
# its fragment after. <seen> holds the fragments followed at this place in
# the value, a newline before and after each.
function follow_ref(ref, value, path, seen, __at, __fragment, __target) {
  __at = index(ref, "#")
  __fragment = (__at > 0) ? substr(ref, __at + 1) : ""

  if (__at != 1 && ref != "") {
    fail(path, "unresolvable $ref '" ref "'")
    return
  }

  __target = pointed_at(__fragment)
  if (!is_schema(__target)) {
    fail(path, "$ref '" ref "' does not resolve to a schema")
  } else if (index(seen, "\n" __fragment "\n") > 0) {
    fail(path, "circular $ref '" ref "'")
  } else {
    validate(__target, value, path, seen "\n" __fragment "\n")
  }
}

# Checks the value against the schema a $ref names.
function check_ref(schema, value, path, seen) {
  if (!has(schema, "$ref")) {
    return
  }
  if (TYPE_OF[member(schema, "$ref")] != "str") {
    fail(path, "$ref must be a string")
    return
  }

  follow_ref(text_of(member(schema, "$ref")), value, path, seen)
}
