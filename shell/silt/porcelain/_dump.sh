#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/dump.sh: @dump.
FRAGMENT

: <<'PUB_FUN'
Answers the SILT document as text for a person to read, for a log or a debug
message. The environment variable SILT_DUMP chooses the format:

  yaml  YAML in block style, as @to_yaml writes it; the default
  json  JSON on several lines, indented by two spaces for each level, as jq
        prints a value
  silt  the document as it is

Refuses any other value of SILT_DUMP.

  doc="$(cat <<'SILT'
  0."a":null
  0."b":list
  1.0:int=1
  SILT
  )"
  @dump text "$doc"

  text is:
    a: null
    b:
      - 1

  with SILT_DUMP=json, text is:
    {
      "a": null,
      "b": [
        1
      ]
    }

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
PUB_FUN
@dump() {
  silt__dump "$@"
}
