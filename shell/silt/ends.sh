#!/bin/sh

: <<'MODULE'
silt__pop, silt__shift, silt__take and silt__take_last: a list with
elements taken from either end.
MODULE

: <<'PUB_FUN'
The plumbing of @pop: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__pop() {
  if [ "$#" -lt 3 ]; then
    __silt__require_list "${2:-}" pop || return 1
    silt__last "$@"
    return
  fi
  __silt__require_list "$3" pop || return 1

  __silt__pop__count=0
  silt__len __silt__pop__count "$3" || return 1
  if [ "$__silt__pop__count" -eq 0 ]; then
    __silt__pop__count=1
  fi

  silt__last "$1" "$3" || return 1
  silt__slice "$2" "$3" 0 "$((__silt__pop__count - 1))"
}

: <<'PUB_FUN'
The plumbing of @shift: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__shift() {
  if [ "$#" -lt 3 ]; then
    __silt__require_list "${2:-}" shift || return 1
    silt__first "$@"
    return
  fi
  __silt__require_list "$3" shift || return 1

  __silt__shift__count=0
  silt__len __silt__shift__count "$3" || return 1

  silt__first "$1" "$3" || return 1
  silt__slice "$2" "$3" 1 "$((__silt__shift__count + 1))"
}

: <<'PUB_FUN'
The plumbing of @take: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__take() {
  __silt__require_list "${2:-}" take || return 1
  __silt__require_index "${3:-}" take || return 1

  __silt__take__count=0
  silt__len __silt__take__count "$2" || return 1
  if [ "$3" -gt "$__silt__take__count" ]; then
    warn "silt: take asked for $3 elements and the list has $__silt__take__count"
  fi

  silt__slice "$1" "$2" 0 "$3"
}

: <<'PUB_FUN'
The plumbing of @take_last: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_lists.sh documents it.
PUB_FUN
silt__take_last() {
  __silt__require_list "${2:-}" take_last || return 1
  __silt__require_index "${3:-}" take_last || return 1

  __silt__take_last__count=0
  silt__len __silt__take_last__count "$2" || return 1
  __silt__take_last__from=$((__silt__take_last__count - $3))
  if [ "$__silt__take_last__from" -lt 0 ]; then
    warn "silt: take_last asked for $3 elements and the list has $__silt__take_last__count"
    __silt__take_last__from=0
  fi

  silt__slice "$1" "$2" "$__silt__take_last__from" "$__silt__take_last__count"
}
