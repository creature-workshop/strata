# The errors the document on stdin meets against the JSON Schema in
# SILT_SPILL, as a list of str, empty when the document is valid:
# silt__validate. An error names the place in the value it was met at, from
# "$" down, and the same error met twice is told once. The keywords read
# are type, enum, const, minLength, maxLength, pattern, minimum, maximum,
# exclusiveMinimum, exclusiveMaximum, multipleOf, required, properties,
# patternProperties, additionalProperties, minItems, maxItems, uniqueItems,
# items, allOf, anyOf, oneOf, not and $ref; any other is passed over.
# Loaded after lines.awk, order.awk and every file under schema/.
#
#   0."n":str="x"   spill  0."properties":map      ->  0.0:str="$.n: expected number, got string"
#                          1."n":map
#                          2."type":str="number"

# Keeps the errors the value meets against the schema at a place in the
# value: none against the schema true, one against the schema false, and
# each keyword's against a map. <seen> holds the references followed to
# this schema at this place. Refuses a schema that is neither.
function validate(schema, value, path, seen) {
  if (TYPE_OF[schema] == "bool") {
    if (VALUE_OF[schema] == "false") {
      fail(path, "value disallowed by 'false' schema")
    }
    return
  }
  if (TYPE_OF[schema] != "map") {
    refuse("a schema is a map or a bool, not " json_text(schema))
  }

  check_ref(schema, value, path, seen)
  check_type(schema, value, path)
  check_enum(schema, value, path)
  check_const(schema, value, path)
  check_string(schema, value, path)
  check_number(schema, value, path)
  check_object(schema, value, path)
  check_array(schema, value, path)
  check_composition(schema, value, path, seen)
}

# Prints the errors kept as a list of str, each told once, in the order
# they were met; the empty list when none was.
function print_errors(__i, __told, __count) {
  __count = 0

  for (__i = 1; __i <= ERRORS; __i++) {
    if (ERROR[__i] in __told) {
      continue
    }

    __told[ERROR[__i]] = 1
    print "0." __count ":str=" wrap(ERROR[__i])
    __count++
  }

  if (__count == 0) {
    print "0.:list"
  }
}

# Keeps every line of the value for END.
function main() {
  take($0)
}

BEGIN {
  order_begin()
  NODES = 0
  ERRORS = 0
}

END {
  if (REFUSED) {
    exit 1
  }

  build_tree(1)
  take_spill()
  build_tree(2)
  validate(ROOT[2], ROOT[1], "$", "")
  print_errors()
}

{ main() }
