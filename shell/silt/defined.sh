#!/bin/sh

: <<'MODULE'
silt__defined and silt__empty: whether a value is present, and whether a
collection has members.
MODULE

: <<'PUB_FUN'
Answers true when the value is a document and is not a null. Answers false
for a null and for the empty string, which is what silt__get answers for a
path that holds nothing.

  silt__defined yes '0.:int=0'   ->  yes=true
  silt__defined yes '0.:null'    ->  yes=false
  silt__defined yes ''           ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The value, a document or the empty string
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
Answers true when a map or a list has no members, and false when it has
any. Refuses every other value: a scalar, a null and the empty string are
not collections, so a missing value is never reported as an empty one.

  silt__empty none '0.:list'       ->  none=true
  silt__empty none '0.0:int=1'     ->  none=false
  silt__empty none '0.:str="x"'    ->  refused: not a map or a list

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
PUB_FUN
silt__empty() {
  __silt__out "$1" || return 1
  __silt__empty__out="$__silt__OUT"

  __silt__empty__kind=''
  if [ -n "$2" ]; then
    silt__type __silt__empty__kind "$2" || return 1
  fi
  __silt__defined__require_map_or_list "$__silt__empty__kind" "$2" || return 1
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
__silt__defined__require_map_or_list() {
  case "$1" in
    map | list) return 0 ;;
  esac

  __silt__fail "empty: not a map or a list: '$2'"
}
