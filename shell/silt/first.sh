#!/bin/sh

: <<'MODULE'
silt__first and silt__last: the element at either end of a list.
MODULE

: <<'PUB_FUN'
The plumbing of @first: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__first() {
  __silt__require_list "$2" first || return 1
  silt__get "$1" "$2" '.[0]'
}

: <<'PUB_FUN'
The plumbing of @last: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__last() {
  __silt__require_list "$2" last || return 1

  __silt__last__count=0
  silt__len __silt__last__count "$2" || return 1
  if [ "$__silt__last__count" -eq 0 ]; then
    __silt__last__count=1
  fi

  silt__get "$1" "$2" ".[$((__silt__last__count - 1))]"
}
