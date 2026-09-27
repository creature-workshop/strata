# Keywords that combine schemas: allOf, anyOf, oneOf and not.
#
# These keywords validate the same value again, so the list of references
# already followed is passed on unchanged. anyOf, oneOf and not only need to
# know whether the value is valid, so the errors from their sub-schemas are
# discarded.
#
# The error messages match the jq validator's messages exactly. Load after
# schema/keywords.awk.
#
#   {"oneOf":[{"type":"number"},{"minimum":0}]} with the value 3
#     ->  $: value matches 2 of oneOf, expected exactly 1

# Returns 1 if the value is valid against the schema. Any errors recorded
# during the check are discarded.
function is_valid(schema, value, path, seen, __before, __met) {
  __before = ERRORS
  validate(schema, value, path, seen)
  __met = ERRORS - __before
  ERRORS = __before

  return __met == 0
}

# Returns the number of schemas in the list that the value is valid against.
function count_valid(list, value, path, seen, __i, __count) {
  __count = 0

  for (__i = 0; __i < COUNT[list]; __i++) {
    if (is_valid(CHILD_AT[list, __i], value, path, seen)) {
      __count++
    }
  }

  return __count
}

# Handles allOf: validates the value against every schema and keeps all of
# the errors.
function check_all_of(schema, value, path, seen, __list, __i) {
  if (!has(schema, "allOf")) {
    return
  }

  __list = collection_operand(schema, "allOf", "list")
  for (__i = 0; __i < COUNT[__list]; __i++) {
    validate(CHILD_AT[__list, __i], value, path, seen)
  }
}

# Handles anyOf: the value must be valid against at least one schema.
function check_any_of(schema, value, path, seen) {
  if (has(schema, "anyOf") && count_valid(collection_operand(schema, "anyOf", "list"), value, path, seen) == 0) {
    add_error(path, "value does not match any of anyOf")
  }
}

# Handles oneOf: the value must be valid against exactly one schema.
function check_one_of(schema, value, path, seen, __count) {
  if (!has(schema, "oneOf")) {
    return
  }

  __count = count_valid(collection_operand(schema, "oneOf", "list"), value, path, seen)
  if (__count != 1) {
    add_error(path, "value matches " __count " of oneOf, expected exactly 1")
  }
}

# Handles not: the value must not be valid against the schema.
function check_not(schema, value, path, seen) {
  if (has(schema, "not") && is_valid(member(schema, "not"), value, path, seen)) {
    add_error(path, "value must not match the 'not' schema")
  }
}

# Runs the four keywords in the order the jq validator reports them.
function check_composition(schema, value, path, seen) {
  check_all_of(schema, value, path, seen)
  check_any_of(schema, value, path, seen)
  check_one_of(schema, value, path, seen)
  check_not(schema, value, path, seen)
}
