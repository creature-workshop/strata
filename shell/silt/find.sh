#!/bin/sh

: <<'MODULE'
silt__find: the first member's value a predicate takes.
MODULE

: <<'PUB_FUN'
Answers the value of the first member the predicate answers true for, as a
document of its own, and the empty string, which no document is, when it
takes none. The walk ends at that member. The predicate is called the way
silt__filter calls one.

  silt__find failed "$tests" has_status failed

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
silt__find() {
  __silt__out "$1" || return 1
  __silt__find__members "$@" || return $?

  __silt__ANSWER="$__silt__HIT"
  __silt__answer__in "$1"
}

: <<'FUN'
Walks the members until the predicate takes one, leaving its value in
__silt__HIT, or nothing when the walk ends without one.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__find__members() {
  __silt__find__members__doc="$2"
  shift 2

  __silt__HIT=''
  silt__each "$__silt__find__members__doc" __silt__find__member "$@"
}

: <<'FUN'
Handles one member: asks the predicate, and when it answers true keeps the
member's value in __silt__HIT and ends the walk.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__find__member() {
  __silt__verdict "$@" || return $?

  if [ "$__silt__VERDICT" = true ]; then
    __silt__HIT="$2"
    __silt__STOP=true
  fi
}
