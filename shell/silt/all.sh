#!/bin/sh

: <<'MODULE'
silt__all: whether a predicate takes every member.
MODULE

: <<'PUB_FUN'
The plumbing of @all: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_all.sh documents it.
PUB_FUN
silt__all() {
  __silt__out "$1" || return 1
  __silt__all__members "$@" || return $?

  __silt__ANSWER="$__silt__ALL"
  __silt__answer__in "$1"
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
__silt__all__members() {
  __silt__all__members__doc="$2"
  shift 2

  __silt__ALL=true
  silt__each "$__silt__all__members__doc" __silt__all__member "$@"
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
__silt__all__member() {
  __silt__verdict "$@" || return $?
  __silt__ALL="$__silt__VERDICT"

  if [ "$__silt__ALL" = false ]; then
    __silt__STOP=true
  fi
}
