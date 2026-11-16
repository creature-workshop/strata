#!/bin/sh

: <<'MODULE'
silt__defined and silt__empty: whether a value is present, and whether a
collection has members.
MODULE

: <<'PUB_FUN'
The plumbing of @defined: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_defined.sh documents it.
PUB_FUN
silt__defined() {
  __silt__out "$1" || return 1

  case "$2" in
    '' | 0.:null) __silt__ANSWER=false ;;
    *) __silt__ANSWER=true ;;
  esac

  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @empty: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_defined.sh documents it.
PUB_FUN
silt__empty() {
  __silt__out "$1" || return 1
  __silt__empty__out="$__silt__OUT"

  __silt__empty__kind=''
  if [ -n "$2" ]; then
    silt__type __silt__empty__kind "$2" || return 1
  fi
  __silt__require_map_or_list "$__silt__empty__kind" "$2" || return 1
  __silt__is_spelled "$2" "0.:$__silt__empty__kind"

  __silt__OUT="$__silt__empty__out"
  __silt__answer
}

: <<'FUN'
Refuses a kind that is not map or list, showing the value in the message.

args:
  $1  The kind silt__type answered, or nothing for the empty string
  $2  The value
FUN
__silt__require_map_or_list() {
  case "$1" in
    map | list) return 0 ;;
  esac

  __silt__fail "empty: not a map or a list: '$2'"
}
