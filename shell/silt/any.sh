#!/bin/sh

: <<'MODULE'
silt__any: whether a predicate takes any member.
MODULE

: <<'PUB_FUN'
Answers true when the predicate answers true for some member, and false
otherwise, the empty collection included. The walk ends at the first member
taken. The predicate is called the way silt__filter calls one.

  silt__any failing "$tests" has_status failed

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
silt__any() {
  __silt__out "$1" || return 1
  __silt__any__members "$@" || return $?

  __silt__ANSWER="$__silt__ANY"
  __silt__answer__in "$1"
}

: <<'FUN'
Walks the members until the predicate takes one, leaving in __silt__ANY
whether it did.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__any__members() {
  __silt__any__members__doc="$2"
  shift 2

  __silt__ANY=false
  silt__each "$__silt__any__members__doc" __silt__any__member "$@"
}

: <<'FUN'
Handles one member: asks the predicate, keeps its answer in __silt__ANY, and
ends the walk when it is true.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__any__member() {
  __silt__verdict "$@" || return $?
  __silt__ANY="$__silt__VERDICT"

  if [ "$__silt__ANY" = true ]; then
    __silt__STOP=true
  fi
}
