#!/bin/sh

: <<'MODULE'
silt__validate and silt__references: validate a document against a JSON
Schema, and list the other schema documents that a schema refers to.
MODULE

: <<'PUB_FUN'
The plumbing of @validate: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_validate.sh documents it.
PUB_FUN
silt__validate() {
  __silt__out "$1" || return 1
  __silt__validate__out="$__silt__OUT"
  __silt__validate__doc="$2"
  __silt__validate__schema="$3"
  shift 3

  __silt__send_ahead "$__silt__validate__schema"
  __silt__send_documents "$@" || return 1
  __silt__ANSWER=''
  __silt__hand_off "$__silt__validate__doc" "$__silt__VALIDATE_PROGRAMS"
  __silt__validate__status=$?
  __silt__clear_documents

  if [ "$__silt__validate__status" -ne 0 ]; then
    return "$__silt__validate__status"
  fi

  __silt__OUT="$__silt__validate__out"
  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @references: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_validate.sh documents it.
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
Sends each of the other schema documents ahead of the value, after the
schema, and lists their keys in __silt__DOCUMENTS, one on each line, in the
order sent. Fails if a key has no document after it.

args:
  $@  For each document: its key, and then the document
FUN
__silt__send_documents() {
  __silt__DOCUMENTS=''

  while [ "$#" -gt 0 ]; do
    if [ "$#" -lt 2 ]; then
      __silt__clear_documents
      __silt__fail "the schema document '$1' has a key and no document"
      return 1
    fi

    __silt__send_document "$1" "$2"
    shift 2
  done
}

: <<'FUN'
Sends one schema document ahead, and adds its key to __silt__DOCUMENTS.

args:
  $1  The key
  $2  The document
FUN
__silt__send_document() {
  __silt__send_ahead "$2"
  __silt__DOCUMENTS="$__silt__DOCUMENTS$1$__silt__NL"
}

: <<'FUN'
Forgets the schema and the other schema documents sent ahead, and their
keys.
FUN
__silt__clear_documents() {
  __silt__clear_ahead
  __silt__DOCUMENTS=''
}

: <<'CONST'
The awk files silt__validate loads, in load order.
CONST
__silt__VALIDATE_PROGRAMS='order schema/tree schema/values schema/keywords schema/patterns schema/keys schema/refs schema/scalars schema/collections schema/composition validate'
