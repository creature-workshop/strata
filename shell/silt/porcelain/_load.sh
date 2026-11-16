#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/load.sh: @load.
FRAGMENT

: <<'PUB_FUN'
Answers the SILT document that a JSON file holds, after checking it against
the JSON Schema in another file. Fails, and says why, when either file does
not exist, when either is not JSON, and when the document does not match the
schema. Each validation error is logged on its own line.

  @load manifest manifest.json schema/manifest.schema.json

A schema that refers to other schema documents is outside what this verb
reads. Use @validate_file for it.

args:
  $1  The name of the variable to answer in
  $2  The JSON file
  $3  The JSON Schema file
PUB_FUN
@load() {
  silt__load "$@"
}
