# The keywords that combine schemas: allOf, anyOf, oneOf and not. Each reads
# the value at the place it already stands, so the references followed to
# reach it are carried on. anyOf, oneOf and not ask only whether the value
# is valid against a schema, and keep none of the errors it met. Loaded
# after schema/keywords.awk.
#
#   {"oneOf":[{"type":"number"},{"minimum":0}]} over 3
#     ->  $: value matches 2 of oneOf, expected exactly 1

# Whether the value is valid against the schema, the errors met on the way
# dropped.
function is_valid(schema, value, path, seen, __before, __met) {
  __before = ERRORS
  validate(schema, value, path, seen)
  __met = ERRORS - __before
  ERRORS = __before

  return __met == 0
}

# How many schemas of a list the value is valid against.
function valid_among(list, value, path, seen, __i, __count) {
  __count = 0

  for (__i = 0; __i < COUNT[list]; __i++) {
    if (is_valid(CHILD_AT[list, __i], value, path, seen)) {
      __count++
    }
  }

  return __count
}

# allOf: the value is valid against every schema, the errors of each kept.
function check_all_of(schema, value, path, seen, __list, __i) {
  if (!has(schema, "allOf")) {
    return
  }

  __list = collection_under(schema, "allOf", "list")
  for (__i = 0; __i < COUNT[__list]; __i++) {
    validate(CHILD_AT[__list, __i], value, path, seen)
  }
}

# anyOf: the value is valid against one schema at least.
function check_any_of(schema, value, path, seen) {
  if (has(schema, "anyOf") && valid_among(collection_under(schema, "anyOf", "list"), value, path, seen) == 0) {
    fail(path, "value does not match any of anyOf")
  }
}

# oneOf: the value is valid against one schema and no more.
function check_one_of(schema, value, path, seen, __count) {
  if (!has(schema, "oneOf")) {
    return
  }

  __count = valid_among(collection_under(schema, "oneOf", "list"), value, path, seen)
  if (__count != 1) {
    fail(path, "value matches " __count " of oneOf, expected exactly 1")
  }
}

# not: the value is not valid against the schema.
function check_not(schema, value, path, seen) {
  if (has(schema, "not") && is_valid(member(schema, "not"), value, path, seen)) {
    fail(path, "value must not match the 'not' schema")
  }
}

# The four keywords, in the order their errors are told.
function check_composition(schema, value, path, seen) {
  check_all_of(schema, value, path, seen)
  check_any_of(schema, value, path, seen)
  check_one_of(schema, value, path, seen)
  check_not(schema, value, path, seen)
}
