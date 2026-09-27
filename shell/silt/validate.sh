#!/bin/sh

: <<'MODULE'
silt__validate: validate a document against a JSON Schema.
MODULE

: <<'PUB_FUN'
Validates a document against a JSON Schema and returns the validation
errors as a list of strings. The schema is also a SILT document. Each error
starts with the path to the invalid value, beginning at "$". A valid
document returns an empty list. When an error shows a map, the map's keys
are in sorted order, so one document always gives the same message.

An invalid document is not a failure: the function returns 0 and the list
of errors. It fails only when the schema itself is invalid, for example
when a keyword has an operand of the wrong type.

Both the document and the schema are treated as the JSON they translate
to. The supported keywords are listed in shell/silt/awk/validate.awk. A
$ref is resolved within the schema document only.

Validation always runs in awk, whatever the size of the document.

  silt__validate errors '0."n":str="x"' '0."properties":map
  1."n":map
  2."type":str="number"'
    ->  errors='0.0:str="$.n: expected number, got string"'

args:
  $1  Name of the variable that receives the result
  $2  The document
  $3  The schema
PUB_FUN
silt__validate() {
  __silt__out "$1" || return 1
  __silt__validate__out="$__silt__OUT"

  __silt__against_spilled "$2" "$3" "$__silt__VALIDATE_PROGRAMS" || return 1

  __silt__OUT="$__silt__validate__out"
  __silt__answer
}

: <<'CONST'
The awk files silt__validate loads, in load order.
CONST
__silt__VALIDATE_PROGRAMS='order schema/tree schema/values schema/keywords schema/patterns schema/refs schema/scalars schema/collections schema/composition validate'
