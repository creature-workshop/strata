#!/bin/sh

: <<'MODULE'
silt__intersect: the elements of one list that another holds too.
MODULE

: <<'PUB_FUN'
The plumbing of @intersect: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_intersect.sh documents it.
PUB_FUN
silt__intersect() {
  __silt__out "$1" || return 1
  __silt__intersect__out="$__silt__OUT"

  __silt__require_list "$2" intersect || return 1
  __silt__require_list "$3" intersect || return 1
  __silt__hand_off_with "$2" "$3" 'order elements intersect' || return 1

  __silt__OUT="$__silt__intersect__out"
  __silt__answer
}
