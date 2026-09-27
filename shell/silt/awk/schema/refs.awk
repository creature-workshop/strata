# Resolves a schema's $ref. The part of a reference before "#" names a
# document, and the part after it is a JSON pointer into that document.
#
# A reference with nothing before the "#" is to the document that contains
# it. Any other reference names another document, in one of two ways:
#
#   - by its key, which is a path relative to the document that contains
#     the reference,
#   - by the "$id" that the other document declares.
#
# These cases are validation errors, not program errors:
#
#   - a reference to a document that was not supplied
#   - a pointer that does not lead to a schema
#   - a circular reference, where following references leads back to a
#     schema already visited for the same value
#
# DOC is the number of the document that contains the schema being checked.
# Load after schema/keys.awk and schema/keywords.awk.
#
#   "#/$defs/name"            ->  the member "name" of the member "$defs"
#                                 of the root of the same document
#   "types.json#/$defs/name"  ->  the same member of the document whose
#                                 key is types.json

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
# a document. Returns 0 if any step of the pointer does not exist.
function resolve_pointer(doc, fragment, __token, __count, __i, __node) {
  __node = ROOT[doc]
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

# Returns the number of the document that declares the "$id", or 0 if none
# of the other documents does.
function document_with_id(id, __doc, __root) {
  for (__doc = 3; __doc <= DOCS; __doc++) {
    __root = ROOT[__doc]
    if (TYPE_OF[__root] == "map" && has(__root, "$id") && TYPE_OF[member(__root, "$id")] == "str" && text_of(member(__root, "$id")) == id) {
      return __doc
    }
  }

  return 0
}

# Returns the number of the document that a reference names, or 0 if that
# document was not supplied. The key is tried first, and then the "$id".
function document_for(uri, __key) {
  if (uri == "") {
    return DOC
  }

  __key = joined_key(KEY_OF_DOC[DOC], uri)
  if (__key in DOC_BY_KEY) {
    return DOC_BY_KEY[__key]
  }

  return document_with_id(uri)
}

# Validates the value against a schema in another document, or in the same
# one. DOC is set to that document while the schema is checked, and set
# back afterwards.
function validate_in(doc, schema, value, path, seen, __outer) {
  __outer = DOC
  DOC = doc
  validate(schema, value, path, seen)
  DOC = __outer
}

# Validates the value against the schema that a reference points to, or
# records an error if the reference cannot be followed.
#
#   ref    The reference as written, for example "#/$defs/name".
#   seen   The schemas already followed for this value, each written as
#          "\n<key#pointer>\n". Used to detect circular references. The
#          brackets keep two entries side by side from looking like an
#          empty entry, which is the root of the schema.
function follow_ref(ref, value, path, seen, __doc, __fragment, __target, __visit) {
  __fragment = pointer_part(ref)
  __doc = document_for(document_part(ref))

  if (__doc == 0) {
    add_error(path, "unresolvable $ref '" ref "'")
    return
  }

  __target = resolve_pointer(__doc, __fragment)
  __visit = "\n<" KEY_OF_DOC[__doc] "#" __fragment ">\n"

  if (!is_schema(__target)) {
    add_error(path, "$ref '" ref "' does not resolve to a schema")
  } else if (index(seen, __visit) > 0) {
    add_error(path, "circular $ref '" ref "'")
  } else {
    validate_in(__doc, __target, value, path, seen __visit)
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
