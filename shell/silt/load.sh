#!/bin/sh

: <<'FRAGMENT'
silt__load: a JSON file read as a document and checked against a schema
file.
FRAGMENT

: <<'PUB_FUN'
Answers the document that a JSON file holds, after checking it against the
JSON Schema in another file. Fails, and says why, when either file does not
exist, when either is not JSON, and when the document does not match the
schema. Each validation error is logged on its own line.

  silt__load manifest manifest.json schema/manifest.schema.json

A schema that refers to other schema documents is outside what this verb
reads. Use silt__validate for it.

args:
  $1  The name of the variable to answer in
  $2  The JSON file
  $3  The JSON Schema file
PUB_FUN
silt__load() {
  __silt__out "$1" || return 1
  __silt__load__out="$__silt__OUT"

  __silt__load__checked "${2:-}" "${3:-}" || return 1
  __silt__answer__in "$__silt__load__out"
}

: <<'FUN'
Sets __silt__ANSWER to the document in a JSON file, and fails when the
document does not match the schema in the schema file.

args:
  $1  The JSON file
  $2  The JSON Schema file
FUN
__silt__load__checked() {
  __silt__load__checked__schema=''
  __silt__load__file __silt__load__checked__schema "$2" || return 1
  __silt__load__checked__doc=''
  __silt__load__file __silt__load__checked__doc "$1" || return 1

  __silt__load__checked__errors=''
  silt__validate __silt__load__checked__errors "$__silt__load__checked__doc" "$__silt__load__checked__schema" || return 1
  if [ "$__silt__load__checked__errors" != 0.:list ]; then
    __silt__load__report_invalid "$1" "$__silt__load__checked__errors"
    return 1
  fi

  __silt__ANSWER="$__silt__load__checked__doc"
}

: <<'FUN'
Reads a JSON file as a document. Fails, and says which file, when the file
does not exist or is not JSON.

args:
  $1  The name of the variable to answer in
  $2  The file
FUN
__silt__load__file() {
  if [ ! -f "$2" ]; then
    __silt__fail "load found no file at '$2'"
    return 1
  fi

  silt__from_json "$1" < "$2" && return 0
  __silt__fail "load could not read '$2' as JSON"
}

: <<'FUN'
Logs that a file does not match its schema, and then each validation
error on its own line.

args:
  $1  The file
  $2  The validation errors, a list of str
FUN
__silt__load__report_invalid() {
  error "silt: '$1' does not match its schema"
  silt__each "$2" __silt__load__report_error
}

: <<'FUN'
Logs one validation error. It is the callback of silt__each.

args:
  $1  The index of the error, unread here
  $2  The error, a str document
FUN
__silt__load__report_error() {
  __silt__load__report_error__text=''
  silt__string __silt__load__report_error__text "$2" . || return 1
  error "silt:   $__silt__load__report_error__text"
}
