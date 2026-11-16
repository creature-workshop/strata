#!/bin/sh

: <<'MODULE'
silt__pluck: the value at a path in each member, as a list.
MODULE

: <<'PUB_FUN'
The plumbing of @pluck: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_pluck.sh documents it.
PUB_FUN
silt__pluck() {
  __silt__out "$1" || return 1
  __silt__pluck__out="$__silt__OUT"

  __silt__COLLECTED='0.:list'
  __silt__KEPT=0
  silt__each "$2" __silt__pluck__member "$3" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__OUT="$__silt__pluck__out"
  __silt__answer
}

: <<'FUN'
Handles one member: appends the value at the path inside it to the list, or
null when it holds none.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The path
FUN
__silt__pluck__member() {
  __silt__PLUCKED=''
  silt__get __silt__PLUCKED "$2" "$3" || return 1

  __silt__keep_member '' "${__silt__PLUCKED:-0.:null}"
}
