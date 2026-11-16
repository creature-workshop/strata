#!/bin/sh

: <<'MODULE'
silt__sort_by: a list with its elements in the order of the values at paths
inside them.
MODULE

: <<'PUB_FUN'
The plumbing of @sort_by: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_sort_by.sh documents it.
PUB_FUN
silt__sort_by() {
  __silt__out "$1" || return 1
  __silt__sort_by__out="$__silt__OUT"
  shift

  __silt__hand_keyed sort_by "$@" || return 1

  __silt__OUT="$__silt__sort_by__out"
  __silt__answer
}
