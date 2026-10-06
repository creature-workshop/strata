#!/bin/sh

: <<'FRAGMENT'
silt__dump: a document as text for a person to read, in the format that
SILT_DUMP names.
FRAGMENT

: <<'PUB_FUN'
Answers the document as text for a person to read, for a log or a debug
message. The environment variable SILT_DUMP chooses the format:

  yaml  YAML in block style, as silt__to_yaml writes it; the default
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
  silt__dump text "$doc"

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
  $2          The document
PUB_FUN
silt__dump() {
  __silt__write_as __silt__dump__write "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document in the format that SILT_DUMP names.

args:
  $1  The document
FUN
__silt__dump__write() {
  case "${SILT_DUMP:-yaml}" in
    yaml) __silt__translate__to_yaml "$1" ;;
    json) __silt__dump__json "$1" ;;
    silt) __silt__dump__silt "$1" ;;
    *) __silt__dump__refuse_format ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to the document as JSON on several lines.

registers:
  __silt__dump__INDENT  The number of spaces for each level while the JSON
                        is written, and empty at any other time

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

: <<'FUN'
Sets __silt__ANSWER to the document as it is.

args:
  $1  The document
FUN
__silt__dump__silt() {
  __silt__ANSWER="$1"
}

: <<'FUN'
Fails with a message that lists the formats SILT_DUMP accepts.
FUN
__silt__dump__refuse_format() {
  __silt__fail "SILT_DUMP accepts yaml, json or silt, not '$SILT_DUMP'"
  return 1
}
