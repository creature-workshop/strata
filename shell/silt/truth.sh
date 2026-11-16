#!/bin/sh

: <<'MODULE'
silt__is_true, silt__is_false and silt__is_zero: whether a document is one
scalar, in the one spelling it has. silt__not: the opposite of a bool.
MODULE

: <<'PUB_FUN'
The plumbing of @is_true: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_truth.sh documents it.
PUB_FUN
silt__is_true() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:bool=true'
  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @is_false: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_truth.sh documents it.
PUB_FUN
silt__is_false() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:bool=false'
  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @is_zero: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_truth.sh documents it.
PUB_FUN
silt__is_zero() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:int=0'
  __silt__answer
}

: <<'PUB_FUN'
The plumbing of @not: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_truth.sh documents it.
PUB_FUN
silt__not() {
  __silt__out "$1" || return 1

  case "$2" in
    0.:bool=true) __silt__ANSWER='0.:bool=false' ;;
    0.:bool=false) __silt__ANSWER='0.:bool=true' ;;
    *)
      __silt__fail "not: not a bool document: '$2'"
      return 1
      ;;
  esac

  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to true when the document is the one line given, byte
for byte, and to false otherwise.

args:
  $1  The document
  $2  The line
FUN
__silt__is_spelled() {
  if [ "$1" = "$2" ]; then
    __silt__ANSWER=true
  else
    __silt__ANSWER=false
  fi
}
