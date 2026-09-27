#!/bin/sh

: <<'MODULE'
silt__join: makes one text from a list.
MODULE

: <<'PUB_FUN'
Joins a list's elements into one text, with the separator between them.
Each element is read the way silt__string reads it: a str unquoted, another
scalar as written, null as the word null. Refuses a list that holds a
collection.

  silt__join text '0.0:str="a"
  0.1:str="b"' ', '   ->  text='a, b'

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The separator; empty when omitted
PUB_FUN
silt__join() {
  __silt__out "$1" || return 1
  __silt__join__out="$__silt__OUT"

  __silt__require_list "$2" join || return 1

  __silt__SEPARATOR="${3-}"
  __silt__ANSWER=''
  __silt__FIRST=true
  __silt__AWK='join'
  __silt__walk "$2" __silt__join_line || return 1

  __silt__OUT="$__silt__join__out"
  __silt__answer
}

: <<'FUN'
Adds one element's text to the answer, with __silt__SEPARATOR before it
unless it is the first. The empty list's line adds nothing. A collection
has no text, so it is refused before its deeper lines are reached.

args:
  $1  The line
FUN
__silt__join_line() {
  case "$1" in
    0.:*) return 0 ;;
  esac

  __silt__parse "$1" || return 1
  if [ "$__silt__LEAF" = false ] && [ "$__silt__TYPE" != null ]; then
    __silt__fail "join of a list holding a collection"
    return 1
  fi

  __silt__join_line__built="$__silt__ANSWER"
  __silt__string_of_scalar "0.:${1#*:}" || return 1

  if [ "$__silt__FIRST" = true ]; then
    __silt__FIRST=false
  else
    __silt__ANSWER="$__silt__join_line__built$__silt__SEPARATOR$__silt__ANSWER"
  fi
}
