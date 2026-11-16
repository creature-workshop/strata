#!/bin/sh

: <<'MODULE'
silt__unique: a list with its repeated values dropped.
MODULE

: <<'PUB_FUN'
The plumbing of @unique: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_unique.sh documents it.
PUB_FUN
silt__unique() {
  __silt__out "$1" || return 1
  __silt__unique__out="$__silt__OUT"

  __silt__require_list "$2" unique || return 1
  __silt__ANSWER=''
  __silt__hand_off "$2" 'order elements unique' || return 1

  __silt__OUT="$__silt__unique__out"
  __silt__answer
}
