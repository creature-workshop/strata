#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/validate_file.sh: @validate_file.
FRAGMENT

: <<'PUB_FUN'
Validates a SILT document against the JSON Schema in a file and returns the
validation errors as a list of strings, as @validate does. A valid
document returns an empty list.

When the schema refers to another schema document, the verb reads that
document from the file its key names, relative to the directory of the
schema file. It does the same for every document those refer to, and reads
each file once. A file that does not exist or is not JSON is left out, and
the errors then name the reference to it.

Fails, and says why, when the schema file does not exist or is not JSON,
and when the schema itself is invalid.

examples:
  schema/manifest.schema.json says that a manifest's name is a string:

    {
      "type": "object",
      "properties": {
        "name": { "type": "string" }
      }
    }

  A manifest whose name is a number has one error:

    @validate_file errors '0."name":int=3' schema/manifest.schema.json
      ->  errors='0.0:str="$.name: expected string, got number"'

  A manifest whose name is a string has none, and the answer is the empty
  list:

    @validate_file errors '0."name":str="tool"' schema/manifest.schema.json
      ->  errors='0.:list'

  The same, with each SILT document written as JSON:

    @validate_file errors {"name":3} schema/manifest.schema.json
      ->  errors=["$.name: expected string, got number"]
    @validate_file errors {"name":"tool"} schema/manifest.schema.json
      ->  errors=[]

args:
  $1  Name of the variable that receives the result
  $2  The SILT document
  $3  The JSON Schema file
PUB_FUN
@validate_file() {
  silt__validate_file "$@"
}
