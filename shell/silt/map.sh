#!/bin/sh

: <<'MODULE'
silt__map: every member's value replaced by what a callback answers.
MODULE

: <<'PUB_FUN'
The plumbing of @map: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_map.sh documents it.
PUB_FUN
silt__map() {
  __silt__shape ''
  __silt__map__shaped "$@"
}

: <<'PUB_FUN'
The plumbing of @mapi: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_map.sh documents it.
PUB_FUN
silt__mapi() {
  __silt__shape i
  __silt__map__shaped "$@"
}

: <<'PUB_FUN'
The plumbing of @mapk: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_map.sh documents it.
PUB_FUN
silt__mapk() {
  __silt__shape k
  __silt__map__shaped "$@"
}

: <<'FUN'
Does the work of silt__map, silt__mapi and silt__mapk for the shape that __silt__shape was given: it walks
the members and answers in the variable named.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The callback
  $@  The extras
FUN
__silt__map__shaped() {
  __silt__out "$1" || return 1
  __silt__map__members "$@" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__answer__in "$1"
}

: <<'FUN'
Walks the members, collecting each one's new value in __silt__COLLECTED.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The callback
  $@  The extras
FUN
__silt__map__members() {
  __silt__map__members__doc="$2"
  shift 2

  __silt__start_collecting "$__silt__map__members__doc" || return 1
  __silt__each__keyed "$__silt__map__members__doc" __silt__map__member "$@"
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
__silt__map__member() {
  __silt__MAPPED=''
  __silt__ask __silt__MAPPED "$@" || return $?

  if [ -z "$__silt__MAPPED" ]; then
    __silt__fail "no document answered for $1"
    return 1
  fi

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__gather__member "$1" "$1" "$__silt__MAPPED" || return 1
  __silt__COLLECTED="$__silt__ANSWER"
}
