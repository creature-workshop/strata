#!/bin/sh

: <<'MODULE'
silt__bool and silt__null: build a bool document and the null document.
MODULE

: <<'PUB_FUN'
Builds a bool document from the word true or the word false. Refuses any
other word.

  silt__bool doc true   ->  doc='0.:bool=true'

args:
  $1  The name of the variable to answer in
  $2  true or false
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
Builds the null document. A null is a value that a record holds on purpose.
It is different from a field that is missing.

  silt__null doc   ->  doc='0.:null'

args:
  $1  The name of the variable to answer in
PUB_FUN
silt__null() {
  __silt__out "$1" || return 1
  __silt__ANSWER='0.:null'
  __silt__answer
}
