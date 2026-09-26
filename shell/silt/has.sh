#!/bin/sh

: <<'MODULE'
silt__has: whether a path holds a value.
MODULE

: <<'PUB_FUN'
Answers true when the document holds a value at the path, a null included,
and false otherwise.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__has() {
  __silt__out "$1" || return 1
  __silt__has__out="$__silt__OUT"

  __silt__has__value=''
  silt__get __silt__has__value "$2" "$3" || return 1

  if [ -n "$__silt__has__value" ]; then
    __silt__ANSWER=true
  else
    __silt__ANSWER=false
  fi

  __silt__OUT="$__silt__has__out"
  __silt__answer
}
