#!/bin/sh

: <<'MODULE'
silt__len: the number of members, or characters of a str.
MODULE

: <<'PUB_FUN'
Answers how many members a map or a list holds, how many characters a str
spells, and 0 for a null.

  silt__len n '0."a":int=1
  0."b":map
  1."c":int=2'   ->  n=2

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__len() {
  __silt__out "$1" || return 1
  __silt__len__out="$__silt__OUT"

  __silt__len__kind=''
  silt__type __silt__len__kind "$2" || return 1

  case "$__silt__len__kind" in
    map | list) __silt__count_members "$2" ;;
    str) __silt__count_characters "$2" || return 1 ;;
    null) __silt__ANSWER=0 ;;
    *)
      __silt__fail "$__silt__len__kind has no length"
      return 1
      ;;
  esac

  __silt__OUT="$__silt__len__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to how many members a map or a list holds: its lines at
depth 0, none for the one keyless line of an empty collection.

args:
  $1  The document
FUN
__silt__count_members() {
  __silt__ANSWER=''
  __silt__AWK='len'
  __silt__walk "$1" __silt__count_line
  __silt__ANSWER="${__silt__ANSWER:-0}"
}

: <<'FUN'
Counts one line of the walk in __silt__ANSWER when it is a member's own line.

args:
  $1  The line
FUN
__silt__count_line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__ANSWER=$((${__silt__ANSWER:-0} + 1)) ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to how many characters a str spells, once unwrapped.

args:
  $1  The document
FUN
__silt__count_characters() {
  __silt__count_characters__literal=''
  __silt__count_characters__text=''

  silt__scalar __silt__count_characters__literal "$1" || return 1
  silt__unwrap __silt__count_characters__text "$__silt__count_characters__literal" || return 1

  __silt__ANSWER="${#__silt__count_characters__text}"
}
