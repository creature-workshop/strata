# Keywords that check a single value: type, enum and const for any value;
# minLength, maxLength and pattern for strings; and minimum, maximum,
# exclusiveMinimum, exclusiveMaximum and multipleOf for numbers.
#
# The error messages match the jq validator's messages exactly. Load after
# schema/keywords.awk and schema/patterns.awk.
#
#   {"type":"string"} with the value 3   ->  $: expected string, got number

# Returns 1 if the value has the named JSON type. The type "integer" matches
# any number that has no fractional part, including 2.0.
function is_of_type(value, name) {
  if (name == json_type(value)) {
    return 1
  }

  return name == "integer" && is_number(value) && number_of(value) == int(number_of(value))
}

# Returns 1 if the value matches the operand of the type keyword, which is
# either one type name or a list of type names.
function type_allowed(types, value, __i) {
  if (TYPE_OF[types] != "list") {
    return is_of_type(value, message_text(types))
  }

  for (__i = 0; __i < COUNT[types]; __i++) {
    if (is_of_type(value, message_text(CHILD_AT[types, __i]))) {
      return 1
    }
  }

  return 0
}

# Handles the type keyword.
function check_type(schema, value, path) {
  if (has(schema, "type") && !type_allowed(member(schema, "type"), value)) {
    add_error(path, "expected " message_text(member(schema, "type")) ", got " json_type(value))
  }
}

# Returns 1 if the list contains a value equal to the given value.
function list_contains(list, value, __i) {
  for (__i = 0; __i < COUNT[list]; __i++) {
    if (comparison_key(CHILD_AT[list, __i]) == comparison_key(value)) {
      return 1
    }
  }

  return 0
}

# Handles the enum keyword: the value must equal one of the listed values.
function check_enum(schema, value, path, __allowed) {
  if (!has(schema, "enum")) {
    return
  }

  __allowed = collection_operand(schema, "enum", "list")
  if (!list_contains(__allowed, value)) {
    add_error(path, "value " message_text(value) " is not in enum " json_text(__allowed))
  }
}

# Handles the const keyword: the value must equal the given value.
function check_const(schema, value, path) {
  if (has(schema, "const") && comparison_key(member(schema, "const")) != comparison_key(value)) {
    add_error(path, "value " message_text(value) " does not equal const " message_text(member(schema, "const")))
  }
}

# Handles minLength and maxLength. Length is counted in characters.
function check_length(schema, value, path, __length) {
  __length = character_count(text_of(value))

  if (has(schema, "minLength") && __length < number_operand(schema, "minLength")) {
    add_error(path, "string length " __length " is below minLength " message_text(member(schema, "minLength")))
  }
  if (has(schema, "maxLength") && __length > number_operand(schema, "maxLength")) {
    add_error(path, "string length " __length " exceeds maxLength " message_text(member(schema, "maxLength")))
  }
}

# Handles the pattern keyword: the string must contain a match.
function check_pattern(schema, value, path) {
  if (has(schema, "pattern") && !matches(text_of(value), string_operand(schema, "pattern"))) {
    add_error(path, "string \"" text_of(value) "\" does not match pattern " string_operand(schema, "pattern"))
  }
}

# Runs the string keywords. Does nothing if the value is not a string.
function check_string(schema, value, path) {
  if (TYPE_OF[value] != "str") {
    return
  }

  check_length(schema, value, path)
  check_pattern(schema, value, path)
}

# Handles minimum and maximum. A value equal to the bound is valid.
function check_bounds(schema, value, path) {
  if (has(schema, "minimum") && number_of(value) < number_operand(schema, "minimum")) {
    add_error(path, "value " message_text(value) " is below minimum " message_text(member(schema, "minimum")))
  }
  if (has(schema, "maximum") && number_of(value) > number_operand(schema, "maximum")) {
    add_error(path, "value " message_text(value) " exceeds maximum " message_text(member(schema, "maximum")))
  }
}

# Handles exclusiveMinimum and exclusiveMaximum. A value equal to the bound
# is not valid.
function check_exclusive_bounds(schema, value, path) {
  if (has(schema, "exclusiveMinimum") && number_of(value) <= number_operand(schema, "exclusiveMinimum")) {
    add_error(path, "value " message_text(value) " is not above exclusiveMinimum " message_text(member(schema, "exclusiveMinimum")))
  }
  if (has(schema, "exclusiveMaximum") && number_of(value) >= number_operand(schema, "exclusiveMaximum")) {
    add_error(path, "value " message_text(value) " is not below exclusiveMaximum " message_text(member(schema, "exclusiveMaximum")))
  }
}

# Handles multipleOf: the value divided by the operand must be a whole
# number. Exits with an error if the operand is 0.
function check_multiple(schema, value, path, __quotient) {
  if (!has(schema, "multipleOf")) {
    return
  }
  if (number_operand(schema, "multipleOf") == 0) {
    refuse("schema error: multipleOf must not be 0")
  }

  __quotient = number_of(value) / number_operand(schema, "multipleOf")
  if (__quotient != int(__quotient)) {
    add_error(path, "value " message_text(value) " is not a multiple of " message_text(member(schema, "multipleOf")))
  }
}

# Runs the number keywords. Does nothing if the value is not a number.
function check_number(schema, value, path) {
  if (!is_number(value)) {
    return
  }

  check_bounds(schema, value, path)
  check_exclusive_bounds(schema, value, path)
  check_multiple(schema, value, path)
}
