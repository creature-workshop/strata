#!/bin/sh

: <<'MODULE'
silt__member: the member a key or an index names.
MODULE

: <<'PUB_FUN'
The plumbing of @member: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_member.sh documents it.
PUB_FUN
silt__member() {
  __silt__out "$1" || return 1

  __silt__member__kind=''
  silt__type __silt__member__kind "${2-}" || return 1
  case "$__silt__member__kind" in
    list) silt__get "$1" "$2" ".[${3-}]" ;;
    map) __silt__member__of_map "$1" "$2" "${3-}" ;;
    *)
      __silt__fail "member reads a map or a list, not a $__silt__member__kind"
      return 1
      ;;
  esac
}

: <<'FUN'
Answers the member of a map under a key given as plain text.

args:
  $1  The name of the variable to answer in
  $2  The map
  $3  The key, as text
FUN
__silt__member__of_map() {
  __silt__wrap_literal "$3"
  silt__get "$1" "$2" ".$__silt__LITERAL"
}
