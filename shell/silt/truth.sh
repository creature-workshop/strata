#!/bin/sh

: <<'MODULE'
silt__is_true, silt__is_false and silt__is_zero: whether a document is one
scalar, in the one spelling it has. silt__not: the opposite of a bool.
MODULE

: <<'PUB_FUN'
Answers true when the document is the bool true, and false for any other
document: the bool false, a str spelling the word, a map, anything.

  silt__is_true yes '0.:bool=true'   ->  yes=true
  silt__is_true yes '0.:str="true"'  ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__is_true() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:bool=true'
  __silt__answer
}

: <<'PUB_FUN'
Answers true when the document is the bool false, and false for any other
document: the bool true, a null, an empty str, anything.

  silt__is_false no '0.:bool=false'   ->  no=true

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__is_false() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:bool=false'
  __silt__answer
}

: <<'PUB_FUN'
Answers true when the document is the int 0, and false for any other
document: the float 0.0, the int -0, the str spelling a zero, anything.

  silt__is_zero none '0.:int=0'   ->  none=true

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__is_zero() {
  __silt__out "$1" || return 1
  __silt__is_spelled "$2" '0.:int=0'
  __silt__answer
}

: <<'PUB_FUN'
Answers the opposite of a bool. Given a bool document, it answers a bool
document. Given the word true or false, which is what a predicate answers,
it answers the other word. Refuses every other value, the empty string
included, so an unset variable is never read as false.

  silt__not off '0.:bool=true'   ->  off='0.:bool=false'
  silt__not no true              ->  no=false

args:
  $1  The name of the variable to answer in
  $2  A bool document, or the word true or false
PUB_FUN
silt__not() {
  __silt__out "$1" || return 1

  case "$2" in
    0.:bool=true) __silt__ANSWER='0.:bool=false' ;;
    0.:bool=false) __silt__ANSWER='0.:bool=true' ;;
    true) __silt__ANSWER=false ;;
    false) __silt__ANSWER=true ;;
    *)
      __silt__fail "not: not a bool: '$2'"
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
