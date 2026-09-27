#!/bin/sh

: <<'MODULE'
silt__validate and silt__references: validate a document against a JSON
Schema, and list the other schema documents that a schema refers to.
MODULE

: <<'PUB_FUN'
Validates a document against a JSON Schema and returns the validation
errors as a list of strings. The schema is also a SILT document. Each error
starts with the path to the invalid value, beginning at "$". A valid
document returns an empty list.

An invalid document is not a failure: the function returns 0. It fails
only when the schema itself is invalid. shell/silt/awk/validate.awk lists
the supported keywords.

If the schema refers to other schema documents, pass each one after the
schema, as its key and then the document. silt__references lists the keys.

  silt__validate errors '0."n":str="x"' '0."properties":map
  1."n":map
  2."type":str="number"'
    ->  errors='0.0:str="$.n: expected number, got string"'

args:
  $1  Name of the variable that receives the result
  $2  The document
  $3  The schema
  $@  For each other schema document: its key, and then the document
PUB_FUN
silt__validate() {
  __silt__out "$1" || return 1
  __silt__validate__out="$__silt__OUT"
  __silt__validate__doc="$2"
  __silt__validate__schema="$3"
  shift 3

  __silt__write_documents "$@" || return 1
  __silt__against_spilled "$__silt__validate__doc" "$__silt__validate__schema" "$__silt__VALIDATE_PROGRAMS"
  __silt__validate__status=$?
  __silt__remove_documents

  if [ "$__silt__validate__status" -ne 0 ]; then
    return "$__silt__validate__status"
  fi

  __silt__OUT="$__silt__validate__out"
  __silt__answer
}

: <<'PUB_FUN'
Returns the keys of the other schema documents that a schema refers to, as
a list of strings in sorted order. A key is the path in a reference,
relative to the schema that contains the reference. A schema that refers to
no other document returns an empty list.

  silt__references keys '0."$ref":str="types.json#/$defs/name"'
    ->  keys='0.0:str="types.json"'

args:
  $1  Name of the variable that receives the result
  $2  The schema
  $3  The key of the schema itself; empty, or left out, for the first schema
PUB_FUN
silt__references() {
  __silt__out "$1" || return 1
  __silt__references__out="$__silt__OUT"

  __silt__BASE="${3-}"
  __silt__ANSWER=''
  __silt__hand_off "$2" 'order schema/keys references'
  __silt__references__status=$?
  __silt__BASE=''

  if [ "$__silt__references__status" -ne 0 ]; then
    return "$__silt__references__status"
  fi

  __silt__OUT="$__silt__references__out"
  __silt__answer
}

: <<'FUN'
Writes each of the other schema documents to its own file, and lists
the keys and the files in __silt__DOCUMENTS: one line for a key, and the
next line for its file. awk reads the documents from the files, so that no
document is passed as an argument. Fails if a key has no document after it.

args:
  $@  For each document: its key, and then the document
FUN
__silt__write_documents() {
  __silt__DOCUMENTS=''
  __silt__DOCUMENT_FILES=''
  __silt__write_documents__count=0

  while [ "$#" -gt 0 ]; do
    if [ "$#" -lt 2 ]; then
      __silt__remove_documents
      __silt__fail "the schema document '$1' has a key and no document"
      return 1
    fi

    __silt__write_documents__count=$((__silt__write_documents__count + 1))
    __silt__write_document "$1" "$2" "${TMPDIR:-/tmp}/silt.$$.document.$__silt__write_documents__count"
    shift 2
  done
}

: <<'FUN'
Writes one schema document to a file, and adds its key and the file to
__silt__DOCUMENTS and the file to __silt__DOCUMENT_FILES.

args:
  $1  The key
  $2  The document
  $3  The file
FUN
__silt__write_document() {
  printf '%s\n' "$2" > "$3"

  __silt__DOCUMENTS="$__silt__DOCUMENTS$1$__silt__NL$3$__silt__NL"
  __silt__DOCUMENT_FILES="$__silt__DOCUMENT_FILES$3$__silt__NL"
}

: <<'FUN'
Removes the files that __silt__write_documents wrote.
FUN
__silt__remove_documents() {
  __silt__split_lines
  # shellcheck disable=SC2086  # split into one file on each line on purpose
  set -- ${__silt__DOCUMENT_FILES-}
  __silt__split_over

  if [ "$#" -gt 0 ]; then
    rm -f "$@"
  fi

  __silt__DOCUMENTS=''
  __silt__DOCUMENT_FILES=''
}

: <<'CONST'
The awk files silt__validate loads, in load order.
CONST
__silt__VALIDATE_PROGRAMS='order schema/tree schema/values schema/keywords schema/patterns schema/keys schema/refs schema/scalars schema/collections schema/composition validate'
