#!/bin/sh

: <<'MODULE'
silt__filter: the members a predicate keeps.
MODULE

: <<'PUB_FUN'
The plumbing of @filter: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_filter.sh documents it.
PUB_FUN
silt__filter() {
  __silt__shape ''
  __silt__filter__shaped "$@"
}

: <<'PUB_FUN'
The plumbing of @filteri: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_filter.sh documents it.
PUB_FUN
silt__filteri() {
  __silt__shape i
  __silt__filter__shaped "$@"
}

: <<'PUB_FUN'
The plumbing of @filterk: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_filter.sh documents it.
PUB_FUN
silt__filterk() {
  __silt__shape k
  __silt__filter__shaped "$@"
}

: <<'FUN'
Does the work of silt__filter, silt__filteri and silt__filterk for the shape that __silt__shape was given: it walks
the members and answers in the variable named.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__filter__shaped() {
  __silt__out "$1" || return 1
  __silt__filter__members "$@" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__answer__in "$1"
}

: <<'FUN'
Walks the members, collecting in __silt__COLLECTED the ones the predicate
keeps.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__filter__members() {
  __silt__filter__members__doc="$2"
  shift 2

  __silt__start_collecting "$__silt__filter__members__doc" || return 1
  __silt__each__keyed "$__silt__filter__members__doc" __silt__filter__member "$@"
}

: <<'FUN'
Handles one member: asks the predicate, and keeps the member when it answers
true.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__filter__member() {
  __silt__verdict "$@" || return $?

  if [ "$__silt__VERDICT" = true ]; then
    __silt__keep_member "$1" "$2" || return 1
  fi
}
