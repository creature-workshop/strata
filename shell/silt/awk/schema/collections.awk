# Keywords that check a map or a list: required, properties,
# patternProperties and additionalProperties for objects; and minItems,
# maxItems, uniqueItems and items for arrays.
#
# When validation moves down to a member or an element, the list of
# references already followed is reset, because circular references are
# detected per value.
#
# The error messages match the jq validator's messages exactly. Load after
# schema/keywords.awk and schema/patterns.awk.
#
#   {"required":["a"]} with the value {}   ->  $: missing required field 'a'

# Handles the required keyword: records an error for each listed field that
# the object does not have.
function check_required(schema, value, path, __list, __i, __name) {
  if (!has(schema, "required")) {
    return
  }

  __list = collection_operand(schema, "required", "list")
  for (__i = 0; __i < COUNT[__list]; __i++) {
    __name = message_text(CHILD_AT[__list, __i])
    if (!has(value, __name)) {
      add_error(path, "missing required field '" __name "'")
    }
  }
}

# Handles the properties keyword: validates each member that the schema
# lists and the object has.
function check_properties(schema, value, path, __map, __i, __name) {
  if (!has(schema, "properties")) {
    return
  }

  __map = collection_operand(schema, "properties", "map")
  for (__i = 0; __i < COUNT[__map]; __i++) {
    __name = NAME_OF[CHILD_AT[__map, __i]]
    if (has(value, __name)) {
      validate(CHILD_AT[__map, __i], member(value, __name), path "." __name, "")
    }
  }
}

# Validates every member of the object whose key matches the pattern.
function check_matching(pattern, schema, value, path, __i, __name) {
  for (__i = 0; __i < COUNT[value]; __i++) {
    __name = NAME_OF[CHILD_AT[value, __i]]
    if (matches(__name, pattern)) {
      validate(schema, CHILD_AT[value, __i], path "." __name, "")
    }
  }
}

# Handles the patternProperties keyword.
function check_pattern_properties(schema, value, path, __map, __i) {
  if (!has(schema, "patternProperties")) {
    return
  }

  __map = collection_operand(schema, "patternProperties", "map")
  for (__i = 0; __i < COUNT[__map]; __i++) {
    check_matching(NAME_OF[CHILD_AT[__map, __i]], CHILD_AT[__map, __i], value, path)
  }
}

# Returns 1 if the key matches any pattern in the schema's
# patternProperties.
function matches_any_pattern(schema, name, __map, __i) {
  if (!has(schema, "patternProperties")) {
    return 0
  }

  __map = member(schema, "patternProperties")
  for (__i = 0; __i < COUNT[__map]; __i++) {
    if (matches(name, NAME_OF[CHILD_AT[__map, __i]])) {
      return 1
    }
  }

  return 0
}

# Returns 1 if the key is not listed in properties and does not match any
# pattern in patternProperties.
function is_additional(schema, name) {
  if (has(schema, "properties") && has(member(schema, "properties"), name)) {
    return 0
  }

  return !matches_any_pattern(schema, name)
}

# Checks one additional member against the operand of additionalProperties.
# If the operand is false, the member is an error. If it is a schema, the
# member is validated against it.
function check_additional(rule, member_node, path) {
  if (TYPE_OF[rule] == "bool" && VALUE_OF[rule] == "false") {
    add_error(path, "unexpected property '" NAME_OF[member_node] "'")
  } else if (TYPE_OF[rule] == "map") {
    validate(rule, member_node, path "." NAME_OF[member_node], "")
  }
}

# Handles the additionalProperties keyword.
function check_additional_properties(schema, value, path, __i) {
  if (!has(schema, "additionalProperties")) {
    return
  }

  for (__i = 0; __i < COUNT[value]; __i++) {
    if (is_additional(schema, NAME_OF[CHILD_AT[value, __i]])) {
      check_additional(member(schema, "additionalProperties"), CHILD_AT[value, __i], path)
    }
  }
}

# Runs the object keywords. Does nothing if the value is not a map.
function check_object(schema, value, path) {
  if (TYPE_OF[value] != "map") {
    return
  }

  check_required(schema, value, path)
  check_properties(schema, value, path)
  check_pattern_properties(schema, value, path)
  check_additional_properties(schema, value, path)
}

# Handles minItems and maxItems.
function check_item_count(schema, value, path) {
  if (has(schema, "minItems") && COUNT[value] < number_operand(schema, "minItems")) {
    add_error(path, "array has " COUNT[value] " items, minimum is " message_text(member(schema, "minItems")))
  }
  if (has(schema, "maxItems") && COUNT[value] > number_operand(schema, "maxItems")) {
    add_error(path, "array has " COUNT[value] " items, maximum is " message_text(member(schema, "maxItems")))
  }
}

# Returns 1 if no two elements of the list are equal.
function items_are_unique(value, __i, __met, __identity) {
  for (__i = 0; __i < COUNT[value]; __i++) {
    __identity = comparison_key(CHILD_AT[value, __i])
    if (__identity in __met) {
      return 0
    }
    __met[__identity] = 1
  }

  return 1
}

# Handles the uniqueItems keyword. Does nothing unless the operand is true.
function check_unique_items(schema, value, path) {
  if (has(schema, "uniqueItems") && VALUE_OF[member(schema, "uniqueItems")] == "true" && !items_are_unique(value)) {
    add_error(path, "array items are not unique")
  }
}

# Handles the items keyword: validates every element against the schema.
function check_items(schema, value, path, __i) {
  if (!has(schema, "items")) {
    return
  }

  for (__i = 0; __i < COUNT[value]; __i++) {
    validate(member(schema, "items"), CHILD_AT[value, __i], path "[" __i "]", "")
  }
}

# Runs the array keywords. Does nothing if the value is not a list.
function check_array(schema, value, path) {
  if (TYPE_OF[value] != "list") {
    return
  }

  check_item_count(schema, value, path)
  check_unique_items(schema, value, path)
  check_items(schema, value, path)
}
