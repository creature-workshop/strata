#!/bin/sh

: <<'MODULE'
silt__all: whether a predicate takes every member.
MODULE

: <<'PUB_FUN'
Answers true when the predicate answers true for every member, the empty
collection included, and false otherwise. The walk ends at the first member
refused. The predicate is called the way silt__filter calls one.

  silt__all clean "$tests" has_status passed

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
silt__all() {
  __silt__out "$1" || return 1
  __silt__all_members "$@" || return $?

  __silt__ANSWER="$__silt__ALL"
  __silt__answer_in "$1"
}

: <<'FUN'
Walks the members until the predicate refuses one, leaving in __silt__ALL
whether it took them all.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__all_members() {
  __silt__all_members__doc="$2"
  shift 2

  __silt__ALL=true
  silt__each __silt__all_member "$__silt__all_members__doc" "$@"
}

: <<'FUN'
Handles one member: asks the predicate, keeps its answer in __silt__ALL, and
ends the walk when it is false.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__all_member() {
  __silt__verdict "$@" || return $?
  __silt__ALL="$__silt__VERDICT"

  if [ "$__silt__ALL" = false ]; then
    __silt__STOP=true
  fi
}
