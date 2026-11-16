#!/bin/sh

: <<'MODULE'
silt__difference: the elements of one list that another does not hold.
MODULE

: <<'PUB_FUN'
The plumbing of @difference: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_difference.sh documents it.
PUB_FUN
silt__difference() {
  __silt__out "$1" || return 1
  __silt__difference__out="$__silt__OUT"

  __silt__require_list "$2" difference || return 1
  __silt__require_list "$3" difference || return 1
  __silt__hand_off_with "$2" "$3" 'order elements difference' || return 1

  __silt__OUT="$__silt__difference__out"
  __silt__answer
}

