# The keywords that read a collection: required, properties,
# patternProperties and additionalProperties over an object, and minItems,
# maxItems, uniqueItems and items over an array. A member is checked at its
# own place in the value, so the references followed to reach it are
# forgotten there. Loaded after schema/keywords.awk and schema/patterns.awk.
#
#   {"required":["a"]} over {}   ->  $: missing required field 'a'

# required: the object holds every field listed.
function check_required(schema, value, path, __list, __i, __name) {
  if (!has(schema, "required")) {
    return
  }

  __list = collection_under(schema, "required", "list")
  for (__i = 0; __i < COUNT[__list]; __i++) {
    __name = said(CHILD_AT[__list, __i])
    if (!has(value, __name)) {
      fail(path, "missing required field '" __name "'")
    }
  }
}

# properties: each member the schema names, where the object holds it, is
# valid against the schema under its name.
function check_properties(schema, value, path, __map, __i, __name) {
  if (!has(schema, "properties")) {
    return
  }

  __map = collection_under(schema, "properties", "map")
  for (__i = 0; __i < COUNT[__map]; __i++) {
    __name = NAME_OF[CHILD_AT[__map, __i]]
    if (has(value, __name)) {
      validate(CHILD_AT[__map, __i], member(value, __name), path "." __name, "")
    }
  }
}

# Every member of the object whose key holds a match of the pattern is
# valid against the pattern's schema.
function check_matching(pattern, schema, value, path, __i, __name) {
  for (__i = 0; __i < COUNT[value]; __i++) {
    __name = NAME_OF[CHILD_AT[value, __i]]
    if (matches(__name, pattern)) {
      validate(schema, CHILD_AT[value, __i], path "." __name, "")
    }
  }
}

# patternProperties: check_matching for each pattern the schema gives.
function check_pattern_properties(schema, value, path, __map, __i) {
  if (!has(schema, "patternProperties")) {
    return
  }

  __map = collection_under(schema, "patternProperties", "map")
  for (__i = 0; __i < COUNT[__map]; __i++) {
    check_matching(NAME_OF[CHILD_AT[__map, __i]], CHILD_AT[__map, __i], value, path)
  }
}

# Whether a key matches a pattern of the schema's patternProperties.
function matches_a_pattern(schema, name, __map, __i) {
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

# Whether a key is one neither properties names nor a pattern matches.
function is_additional(schema, name) {
  if (has(schema, "properties") && has(member(schema, "properties"), name)) {
    return 0
  }

  return !matches_a_pattern(schema, name)
}

# One additional member against what additionalProperties gives: refused
# by false, and valid against a schema.
function check_additional(rule, member_node, path) {
  if (TYPE_OF[rule] == "bool" && VALUE_OF[rule] == "false") {
    fail(path, "unexpected property '" NAME_OF[member_node] "'")
  } else if (TYPE_OF[rule] == "map") {
    validate(rule, member_node, path "." NAME_OF[member_node], "")
  }
}

# additionalProperties: check_additional for each additional member.
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

# The keywords over an object, skipped for any other value.
function check_object(schema, value, path) {
  if (TYPE_OF[value] != "map") {
    return
  }

  check_required(schema, value, path)
  check_properties(schema, value, path)
  check_pattern_properties(schema, value, path)
  check_additional_properties(schema, value, path)
}

# minItems and maxItems: the array's length is within them.
function check_item_count(schema, value, path) {
  if (has(schema, "minItems") && COUNT[value] < number_under(schema, "minItems")) {
    fail(path, "array has " COUNT[value] " items, minimum is " said(member(schema, "minItems")))
  }
  if (has(schema, "maxItems") && COUNT[value] > number_under(schema, "maxItems")) {
    fail(path, "array has " COUNT[value] " items, maximum is " said(member(schema, "maxItems")))
  }
}

# Whether no two elements of the array are the same value.
function all_differ(value, __i, __met, __identity) {
  for (__i = 0; __i < COUNT[value]; __i++) {
    __identity = identity(CHILD_AT[value, __i])
    if (__identity in __met) {
      return 0
    }
    __met[__identity] = 1
  }

  return 1
}

# uniqueItems: where it is true, no two elements are the same value.
function check_unique_items(schema, value, path) {
  if (has(schema, "uniqueItems") && VALUE_OF[member(schema, "uniqueItems")] == "true" && !all_differ(value)) {
    fail(path, "array items are not unique")
  }
}

# items: every element is valid against the schema.
function check_items(schema, value, path, __i) {
  if (!has(schema, "items")) {
    return
  }

  for (__i = 0; __i < COUNT[value]; __i++) {
    validate(member(schema, "items"), CHILD_AT[value, __i], path "[" __i "]", "")
  }
}

# The keywords over an array, skipped for any other value.
function check_array(schema, value, path) {
  if (TYPE_OF[value] != "list") {
    return
  }

  check_item_count(schema, value, path)
  check_unique_items(schema, value, path)
  check_items(schema, value, path)
}
