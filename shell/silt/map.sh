#!/bin/sh

: <<'MODULE'
silt__map: every member's value replaced by what a callback answers.
MODULE

: <<'PUB_FUN'
Answers a document of the same kind as the one given, each member's value
replaced by the document the callback answers for it: a map keeps its keys,
a list its indices. The callback is called with the name of the variable to
answer in, the member's key as text, its value as a document, and the extra
arguments after them. It can run any verb, a loop of its own included.

  key_of() { silt__str "$1" "$2"; }
  silt__map named "$doc" key_of   ->  every value the str of its key

  callback <out> <key> <value> [extras...]  ->  answers a document in <out>

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The callback
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
silt__map() {
  __silt__out "$1" || return 1
  __silt__map_members "$@" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__answer_in "$1"
}

: <<'FUN'
Walks the members, collecting each one's new value in __silt__COLLECTED.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The callback
  $@  The extras
FUN
__silt__map_members() {
  __silt__map_members__doc="$2"
  shift 2

  __silt__start_collecting "$__silt__map_members__doc" || return 1
  silt__each "$__silt__map_members__doc" __silt__map_member "$@"
}

: <<'FUN'
Handles one member: asks the callback for its new value, then appends that
under the member's key.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The callback
  $@  The extras
FUN
__silt__map_member() {
  __silt__MAPPED=''
  __silt__ask __silt__MAPPED "$@" || return $?

  if [ -z "$__silt__MAPPED" ]; then
    __silt__fail "no document answered for $1"
    return 1
  fi

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__gather_member "$1" "$1" "$__silt__MAPPED" || return 1
  __silt__COLLECTED="$__silt__ANSWER"
}
