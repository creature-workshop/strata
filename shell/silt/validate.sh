#!/bin/sh

: <<'MODULE'
silt__validate: the errors a document meets against a JSON Schema.
MODULE

: <<'PUB_FUN'
Answers the errors a document meets against a JSON Schema, itself a
document, as a list of str: each names the place in the value it was met
at, from "$" down, and a valid document answers the empty list. The
document and the schema are read as the JSON they translate to. The
keywords read are those of draft 2020-12 that shell/silt/awk/validate.awk
lists, a $ref followed within the schema's own document. Refuses a schema
that is no schema, a keyword whose operand is of the wrong kind among
them. This runs in awk whatever the document's size, the schema reaching
it through the spill file.

  silt__validate errors '0."n":str="x"' '0."properties":map
  1."n":map
  2."type":str="number"'
    ->  errors='0.0:str="$.n: expected number, got string"'

args:
  $1  The name of the variable to answer in
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
The awk programs silt__validate runs, in the order they load.
CONST
__silt__VALIDATE_PROGRAMS='order schema/tree schema/values schema/keywords schema/patterns schema/refs schema/scalars schema/collections schema/composition validate'
