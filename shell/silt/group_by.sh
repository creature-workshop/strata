#!/bin/sh

: <<'MODULE'
silt__group_by: a list's elements gathered into lists of the ones that hold
the same values at paths inside them.
MODULE

: <<'PUB_FUN'
The plumbing of @group_by: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_group_by.sh documents it.
PUB_FUN
silt__group_by() {
  __silt__out "$1" || return 1
  __silt__group_by__out="$__silt__OUT"
  shift

  __silt__hand_keyed group_by "$@" || return 1

  __silt__OUT="$__silt__group_by__out"
  __silt__answer
}
