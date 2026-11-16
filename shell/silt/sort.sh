#!/bin/sh

: <<'MODULE'
silt__sort: a list with its elements in the order of their values.
MODULE

: <<'PUB_FUN'
The plumbing of @sort: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_sort.sh documents it.
PUB_FUN
silt__sort() {
  __silt__out "$1" || return 1
  __silt__sort__out="$__silt__OUT"

  __silt__require_list "${2-}" sort || return 1
  __silt__ANSWER=''
  __silt__hand_off "$2" 'order elements sorting sort' || return 1

  __silt__OUT="$__silt__sort__out"
  __silt__answer
}
