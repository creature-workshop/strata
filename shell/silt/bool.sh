#!/bin/sh

: <<'MODULE'
silt__bool and silt__null: build a bool document and the null document.
MODULE

: <<'PUB_FUN'
The plumbing of @bool: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_bool.sh documents it.
PUB_FUN
silt__bool() {
  __silt__out "$1" || return 1

  case "$2" in
    true | false) __silt__ANSWER="0.:bool=$2" ;;
    *)
      __silt__fail "bool: not true or false: '$2'"
      return 1
      ;;
  esac

  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @null: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_bool.sh documents it.
PUB_FUN
silt__null() {
  __silt__out "$1" || return 1
  __silt__ANSWER='0.:null'
  __silt__answer
}
