# A schema's keywords read with their operands checked, and an error kept.
# A keyword whose operand is of the wrong kind is refused, since the schema
# is then at fault and not the value. It holds functions alone. Loaded after
# schema/tree.awk and schema/values.awk.
#
#   ERROR[1..ERRORS]   the errors kept, in the order they were met

# Keeps an error against the place in the value it was met at.
function fail(path, message) {
  ERRORS++
  ERROR[ERRORS] = path ": " message
}

# The number a keyword gives. Refuses any other operand.
function number_under(schema, keyword) {
  if (!is_number(member(schema, keyword))) {
    refuse("a schema's " keyword " takes a number, not " json_text(member(schema, keyword)))
  }

  return number_of(member(schema, keyword))
}

# The text a keyword gives. Refuses any other operand.
function text_under(schema, keyword) {
  if (TYPE_OF[member(schema, keyword)] != "str") {
    refuse("a schema's " keyword " takes a string, not " json_text(member(schema, keyword)))
  }

  return text_of(member(schema, keyword))
}

# The collection a keyword gives, of the kind named, map or list. Refuses
# any other operand.
function collection_under(schema, keyword, kind) {
  if (TYPE_OF[member(schema, keyword)] != kind) {
    refuse("a schema's " keyword " takes a " kind ", not " json_text(member(schema, keyword)))
  }

  return member(schema, keyword)
}
