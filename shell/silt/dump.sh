#!/bin/sh

: <<'MODULE'
silt__dump: a document as JSON on several lines, for a person to read.
MODULE

: <<'PUB_FUN'
Answers the document as JSON on several lines: each member on its own
line, indented by two spaces for each level, with a space after the colon
of a key. An empty map is {} and an empty list is []. It is what jq prints
for a value by default.

  doc="$(cat <<'SILT'
  0."a":null
  0."b":list
  1.0:int=1
  SILT
  )"
  silt__dump text "$doc"

  text is:
    {
      "a": null,
      "b": [
        1
      ]
    }

registers:
  __silt__dump__INDENT  The number of spaces for each level while the JSON
                        is written, and empty at any other time

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
PUB_FUN
silt__dump() {
  __silt__write_as __silt__dump__json "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as JSON on several lines.

args:
  $1  The document
FUN
__silt__dump__json() {
  __silt__dump__INDENT=2
  __silt__dump__json__status=0
  __silt__hand_off "$1" translators/json/to || __silt__dump__json__status=$?
  __silt__dump__INDENT=''

  return "$__silt__dump__json__status"
}
