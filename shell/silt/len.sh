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
  __silt__len__literal=''
  __silt__len__text=''
  silt__type __silt__len__kind "$2" || return 1
  case "$__silt__len__kind" in
    map | list)
      __silt__len__count=0
      __silt__len__ifs="$IFS"
      IFS="$__silt__NL"
      set -f
      # shellcheck disable=SC2086
      set -- $2
      set +f
      IFS="$__silt__len__ifs"
      for __silt__len__line do
        case "$__silt__len__line" in
          0.*) __silt__len__count=$((__silt__len__count + 1)) ;;
        esac
      done
      case "$1" in
        0.:map | 0.:list) __silt__len__count=0 ;;
      esac
      __silt__ANSWER="$__silt__len__count"
      ;;
    str)
      silt__scalar __silt__len__literal "$2" || return 1
      silt__unwrap __silt__len__text "$__silt__len__literal" || return 1
      __silt__ANSWER="${#__silt__len__text}"
      ;;
    null)
      __silt__ANSWER=0
      ;;
    *)
      __silt__fail "$__silt__len__kind has no length"
      return 1
      ;;
  esac
  __silt__OUT="$__silt__len__out"
  __silt__answer
}
