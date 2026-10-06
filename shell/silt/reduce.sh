#!/bin/sh

: <<'FRAGMENT'
silt__reduce: one value built from the members of a map or a list, a
member at a time.
FRAGMENT

: <<'PUB_FUN'
Answers the value that a callback builds from the members of a map or a
list. The callback is called once for each member, in order. It receives
the value built so far and answers the next one. The value starts as the
empty list, or as the document after --from.

The callback is called with the name of the variable to answer in, the
member's key as text, its value as a document, the value built so far, and
the extra arguments after them. It can run any verb, a loop of its own
included.

  add_length() { silt__len n "$3"; silt__scalar so_far "$4"; eval "$1=0.:int=\$((so_far + n))"; }
  silt__reduce total "$tests" add_length --from '0.:int=0'

  callback <out> <key> <value> <so far> [extras...]  ->  answers a document in <out>

registers:
  __silt__reduce__REDUCED  The value built so far

args:
  $1      The name of the variable to answer in
  $2      The document, a map or a list
  $3      The callback
  --from  The document the value starts as; the empty list when not given
  $@      Extra arguments the callback receives after the value built so far
PUB_FUN
silt__reduce() {
  __silt__out "$1" || return 1
  __silt__reduce__members "$@" || return $?

  __silt__ANSWER="$__silt__reduce__REDUCED"
  __silt__answer__in "$1"
}

: <<'FUN'
Walks the members, and keeps the value the callback builds in
__silt__reduce__REDUCED.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The callback
  $@  --from and its document when given, then the extras
FUN
__silt__reduce__members() {
  __silt__reduce__members__doc="$2"
  __silt__reduce__members__callback="${3:-}"
  shift "$(($# < 3 ? $# : 3))"

  __silt__reduce__REDUCED='0.:list'
  if [ "${1:-}" = --from ]; then
    __silt__reduce__from "$@" || return 1
    shift 2
  fi

  silt__each "$__silt__reduce__members__doc" __silt__reduce__member "$__silt__reduce__members__callback" "$@"
}

: <<'FUN'
Keeps the document after --from as the value that the callback starts
with. Refuses --from with no document after it.

args:
  $1  --from
  $2  The document
FUN
__silt__reduce__from() {
  if [ "$#" -lt 2 ] || [ -z "$2" ]; then
    __silt__fail '--from requires a document'
    return 1
  fi

  __silt__reduce__REDUCED="$2"
}

: <<'FUN'
Handles one member: gives the callback the value built so far, and keeps
the value it answers.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The callback
  $@  The extras
FUN
__silt__reduce__member() {
  __silt__reduce__member__key="$1"
  __silt__reduce__member__value="$2"
  __silt__reduce__member__callback="$3"
  shift 3

  __silt__reduce__NEXT=''
  __silt__ask __silt__reduce__NEXT "$__silt__reduce__member__key" "$__silt__reduce__member__value" "$__silt__reduce__member__callback" "$__silt__reduce__REDUCED" "$@" || return $?

  if [ -z "$__silt__reduce__NEXT" ]; then
    __silt__fail "no document answered for $__silt__reduce__member__key"
    return 1
  fi
  __silt__reduce__REDUCED="$__silt__reduce__NEXT"
}
