# The keywords that read the value by itself: type, enum and const over any
# value, minLength, maxLength and pattern over a string, and minimum,
# maximum, exclusiveMinimum, exclusiveMaximum and multipleOf over a number.
# Loaded after schema/keywords.awk and schema/patterns.awk.
#
#   {"type":"string"} over 3   ->  $: expected string, got number

# Whether the value is of the type named: by JSON's name for it, and an
# integer a number with no fraction.
function is_of_type(value, name) {
  if (name == json_type(value)) {
    return 1
  }

  return name == "integer" && is_number(value) && number_of(value) == int(number_of(value))
}

# Whether the value is of a type the keyword allows, one name or a list of
# them.
function type_allowed(types, value, __i) {
  if (TYPE_OF[types] != "list") {
    return is_of_type(value, said(types))
  }

  for (__i = 0; __i < COUNT[types]; __i++) {
    if (is_of_type(value, said(CHILD_AT[types, __i]))) {
      return 1
    }
  }

  return 0
}

# type: the value is of the type, or of one of the types.
function check_type(schema, value, path) {
  if (has(schema, "type") && !type_allowed(member(schema, "type"), value)) {
    fail(path, "expected " said(member(schema, "type")) ", got " json_type(value))
  }
}

# Whether a list holds a value the same as the one given.
function holds(list, value, __i) {
  for (__i = 0; __i < COUNT[list]; __i++) {
    if (identity(CHILD_AT[list, __i]) == identity(value)) {
      return 1
    }
  }

  return 0
}

# enum: the value is one of those listed.
function check_enum(schema, value, path, __allowed) {
  if (!has(schema, "enum")) {
    return
  }

  __allowed = collection_under(schema, "enum", "list")
  if (!holds(__allowed, value)) {
    fail(path, "value " said(value) " is not in enum " json_text(__allowed))
  }
}

# const: the value is the one given.
function check_const(schema, value, path) {
  if (has(schema, "const") && identity(member(schema, "const")) != identity(value)) {
    fail(path, "value " said(value) " does not equal const " said(member(schema, "const")))
  }
}

# minLength and maxLength: the string's length in characters is within them.
function check_length(schema, value, path, __length) {
  __length = chars(text_of(value))

  if (has(schema, "minLength") && __length < number_under(schema, "minLength")) {
    fail(path, "string length " __length " is below minLength " said(member(schema, "minLength")))
  }
  if (has(schema, "maxLength") && __length > number_under(schema, "maxLength")) {
    fail(path, "string length " __length " exceeds maxLength " said(member(schema, "maxLength")))
  }
}

# pattern: the string holds a match of it.
function check_pattern(schema, value, path) {
  if (has(schema, "pattern") && !matches(text_of(value), text_under(schema, "pattern"))) {
    fail(path, "string \"" text_of(value) "\" does not match pattern " text_under(schema, "pattern"))
  }
}

# The keywords over a string, skipped for any other value.
function check_string(schema, value, path) {
  if (TYPE_OF[value] != "str") {
    return
  }

  check_length(schema, value, path)
  check_pattern(schema, value, path)
}

# minimum and maximum: the number is within them, either bound allowed.
function check_bounds(schema, value, path) {
  if (has(schema, "minimum") && number_of(value) < number_under(schema, "minimum")) {
    fail(path, "value " said(value) " is below minimum " said(member(schema, "minimum")))
  }
  if (has(schema, "maximum") && number_of(value) > number_under(schema, "maximum")) {
    fail(path, "value " said(value) " exceeds maximum " said(member(schema, "maximum")))
  }
}

# exclusiveMinimum and exclusiveMaximum: the number is between them, neither
# bound allowed.
function check_exclusive_bounds(schema, value, path) {
  if (has(schema, "exclusiveMinimum") && number_of(value) <= number_under(schema, "exclusiveMinimum")) {
    fail(path, "value " said(value) " is not above exclusiveMinimum " said(member(schema, "exclusiveMinimum")))
  }
  if (has(schema, "exclusiveMaximum") && number_of(value) >= number_under(schema, "exclusiveMaximum")) {
    fail(path, "value " said(value) " is not below exclusiveMaximum " said(member(schema, "exclusiveMaximum")))
  }
}

# multipleOf: the number divides by it with nothing left over.
function check_multiple(schema, value, path, __quotient) {
  if (!has(schema, "multipleOf")) {
    return
  }
  if (number_under(schema, "multipleOf") == 0) {
    refuse("a schema's multipleOf takes a number other than 0")
  }

  __quotient = number_of(value) / number_under(schema, "multipleOf")
  if (__quotient != int(__quotient)) {
    fail(path, "value " said(value) " is not a multiple of " said(member(schema, "multipleOf")))
  }
}

# The keywords over a number, skipped for any other value.
function check_number(schema, value, path) {
  if (!is_number(value)) {
    return
  }

  check_bounds(schema, value, path)
  check_exclusive_bounds(schema, value, path)
  check_multiple(schema, value, path)
}
