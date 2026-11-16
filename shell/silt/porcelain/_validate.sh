#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/validate.sh: @validate, @references.
FRAGMENT

: <<'PUB_FUN'
Validates a SILT document against a JSON Schema and returns the validation
errors as a list of strings. The schema is also a SILT document. Each error
starts with the path to the invalid value, beginning at "$". A valid
document returns an empty list.

An invalid document is not a failure: the function returns 0. It fails
only when the schema itself is invalid. shell/silt/awk/validate.awk lists
the supported keywords.

If the schema refers to other schema documents, pass each one after the
schema, as its key and then the document. @references lists the keys.

  schema="$(cat <<'SILT'
  0."properties":map
  1."n":map
  2."type":str="number"
  SILT
  )"
  @validate errors '0."n":str="x"' "$schema"   ->  errors='0.0:str="$.n: expected number, got string"'

  The same, with each SILT document written as JSON:

    @validate errors {"n":"x"} {"properties":{"n":{"type":"number"}}}   ->  errors=["$.n: expected number, got string"]

args:
  $1  Name of the variable that receives the result
  $2  The SILT document
  $3  The schema
  $@  For each other schema document: its key, and then the SILT document
PUB_FUN
@validate() {
  silt__validate "$@"
}

: <<'PUB_FUN'
Returns the keys of the other schema documents that a schema refers to, as
a list of strings in sorted order. A key is the path in a reference,
relative to the schema that contains the reference. A schema that refers to
no other SILT document returns an empty list.

  @references keys '0."$ref":str="types.json#/$defs/name"'   ->  keys='0.0:str="types.json"'

  The same, with each SILT document written as JSON:

    @references keys {"$ref":"types.json#/$defs/name"}   ->  keys=["types.json"]

args:
  $1  Name of the variable that receives the result
  $2  The schema
  $3  The key of the schema itself; empty, or left out, for the first schema
PUB_FUN
@references() {
  silt__references "$@"
}
