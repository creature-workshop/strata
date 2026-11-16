#!/bin/sh

: <<'FRAGMENT'
silt__dump: a document as text for a person to read, in the format that
SILT_DUMP names.
FRAGMENT

: <<'PUB_FUN'
The plumbing of @dump: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_dump.sh documents it.
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
