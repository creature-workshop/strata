# Functions for recording a validation error and for reading a keyword's
# operand from a schema. If an operand has the wrong type, the schema is
# invalid, so the program exits with an error instead of recording a
# validation error. This file contains functions only. Load after
# schema/tree.awk and schema/values.awk.
#
#   ERROR[1..ERRORS]   the recorded errors, in the order they were found

# Records a validation error for the value at the given path.
function add_error(path, message) {
  ERRORS++
  ERROR[ERRORS] = path ": " message
}

# Returns the operand of a keyword as a number. Exits with an error if the
# operand is not a number.
function number_operand(schema, keyword) {
  if (!is_number(member(schema, keyword))) {
    refuse("schema error: " keyword " must be a number, got " json_text(member(schema, keyword)))
  }

  return number_of(member(schema, keyword))
}

# Returns the operand of a keyword as text. Exits with an error if the
# operand is not a string.
function string_operand(schema, keyword) {
  if (TYPE_OF[member(schema, keyword)] != "str") {
    refuse("schema error: " keyword " must be a string, got " json_text(member(schema, keyword)))
  }

  return text_of(member(schema, keyword))
}

# Returns the node of a keyword's operand, which must be of the given kind,
# map or list. Exits with an error if it is not.
function collection_operand(schema, keyword, kind) {
  if (TYPE_OF[member(schema, keyword)] != kind) {
    refuse("schema error: " keyword " must be a " kind ", got " json_text(member(schema, keyword)))
  }

  return member(schema, keyword)
}
