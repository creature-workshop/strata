#!/bin/sh

: <<'MODULE'
silt__is_true, silt__is_false and silt__is_zero: whether a document is one
scalar, in the one spelling it has.
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
