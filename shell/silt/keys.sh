#!/bin/sh

# silt__keys: the members' keys, as a list document.

: <<'PUB_FUN'
Answers the members' keys as a list document: a map's as str leaves holding
the key literals in the order they sit, a list's as int leaves.

  silt__keys names '0."b":int=1
  0."a":int=2'   ->  names='0.0:str="b"
  0.1:str="a"'

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__keys() {
  __silt__out "$1" || return 1
  __silt__keys__out="$__silt__OUT"
  __silt__keys__kind=''
  silt__type __silt__keys__kind "$2" || return 1
  case "$__silt__keys__kind" in
    map | list) ;;
    *)
      __silt__fail "$__silt__keys__kind has no keys"
      return 1
      ;;
  esac
  __silt__ANSWER=''
  __silt__keys__index=0
  __silt__keys__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__keys__ifs"
  for __silt__keys__line do
    case "$__silt__keys__line" in
      0.:*) break ;;
      0.*) ;;
      *) continue ;;
    esac
    __silt__parse "$__silt__keys__line" || return 1
    case "$__silt__keys__kind" in
      map) __silt__emit "0.$__silt__keys__index:str=$__silt__KEY" ;;
      *) __silt__emit "0.$__silt__keys__index:int=$__silt__KEY" ;;
    esac
    __silt__keys__index=$((__silt__keys__index + 1))
  done
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi
  __silt__OUT="$__silt__keys__out"
  __silt__answer
}
