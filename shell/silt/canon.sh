#!/bin/sh

: <<'MODULE'
silt__canon and silt__equals: one order for a map's members, and equality
that looks past the order.
MODULE

: <<'PUB_FUN'
The plumbing of @canon: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_canon.sh documents it.
PUB_FUN
silt__canon() {
  __silt__out "$1" || return 1
  __silt__canon__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__hand_off "$2" 'order canon' || return 1

  __silt__OUT="$__silt__canon__out"
  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @equals: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_canon.sh documents it.
PUB_FUN
silt__equals() {
  __silt__out "$1" || return 1
  __silt__equals__out="$__silt__OUT"

  if [ "$2" = "$3" ]; then
    __silt__ANSWER=true
  else
    __silt__equals_canonical "$2" "$3" || return 1
  fi

  __silt__OUT="$__silt__equals__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to true when the two documents are the same once each
is in canonical order, and to false otherwise.

args:
  $1  One document
  $2  The other
FUN
__silt__equals_canonical() {
  __silt__equals_canonical__one=''
  __silt__equals_canonical__other=''
  silt__canon __silt__equals_canonical__one "$1" || return 1
  silt__canon __silt__equals_canonical__other "$2" || return 1

  if [ "$__silt__equals_canonical__one" = "$__silt__equals_canonical__other" ]; then
    __silt__ANSWER=true
  else
    __silt__ANSWER=false
  fi
}
