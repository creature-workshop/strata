# Validates the document on stdin against the JSON Schema in the file named
# by SILT_SPILL, and prints the validation errors as a list of strings. Prints
# an empty list if the document is valid. This is the awk program behind
# silt__validate.
#
# Each error starts with the path to the invalid value, beginning at "$".
# Duplicate errors are printed once.
#
# Supported keywords: type, enum, const, minLength, maxLength, pattern,
# minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf, required,
# properties, patternProperties, additionalProperties, minItems, maxItems,
# uniqueItems, items, allOf, anyOf, oneOf, not and $ref. Other keywords are
# ignored.
#
# Load after lines.awk, order.awk and every file under schema/.
#
#   0."n":str="x"   schema  0."properties":map      ->  0.0:str="$.n: expected number, got string"
#                           1."n":map
#                           2."type":str="number"

# Validates one value against one schema and records any errors.
#
#   schema  The schema node. A schema of true accepts every value, and a
#           schema of false rejects every value.
#   value   The value node.
#   path    The path to the value, used in error messages.
#   seen    The $ref targets already followed for this value, used to detect
#           circular references.
#
# Exits with an error if the schema is neither a map nor a bool.
function validate(schema, value, path, seen) {
  if (TYPE_OF[schema] == "bool") {
    if (VALUE_OF[schema] == "false") {
      add_error(path, "value disallowed by 'false' schema")
    }
    return
  }
  if (TYPE_OF[schema] != "map") {
    refuse("schema error: a schema must be a map or a bool, got " json_text(schema))
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

# Prints the recorded errors as a list of strings, in the order they were
# found, skipping duplicates. Prints an empty list if there are none.
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

# Stores each input line so the END block can process the whole document.
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
  read_schema_lines()
  build_tree(2)
  validate(ROOT[2], ROOT[1], "$", "")
  print_errors()
}

{ main() }
