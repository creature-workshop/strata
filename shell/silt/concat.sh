#!/bin/sh

: <<'MODULE'
silt__concat: joins two lists end to end.
MODULE

: <<'PUB_FUN'
Appends the second list's elements to the first, renumbering them to carry
on from the first list's count.

  silt__concat doc '0.0:str="a"' '0.0:str="b"'   ->  doc='0.0:str="a"
                                                          0.1:str="b"'

args:
  $1  The name of the variable to answer in
  $2  The first list
  $3  The second list
PUB_FUN
silt__concat() {
  __silt__out "$1" || return 1
  __silt__concat__out="$__silt__OUT"

  __silt__require_list "$2" concat || return 1
  __silt__require_list "$3" concat || return 1
  __silt__continue_list "$2"
  __silt__walk "$3" __silt__append_list_line || return 1

  __silt__answer_list
  __silt__OUT="$__silt__concat__out"
  __silt__answer
}

: <<'FUN'
Appends one line of the second list: an element's own line with its index
moved on by __silt__INDEX, a deeper line as it is, and the empty list's line
not at all.

args:
  $1  The line
FUN
__silt__append_list_line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__append_element "$1" ;;
    *) __silt__emit "$1" ;;
  esac
}

: <<'FUN'
Appends one element's own line with its index moved on by __silt__INDEX.

args:
  $1  The element's depth-0 line
FUN
__silt__append_element() {
  __silt__append_element__rest="${1#0.}"
  __silt__append_element__index="${__silt__append_element__rest%%:*}"
  __silt__emit "0.$((__silt__append_element__index + __silt__INDEX)):${__silt__append_element__rest#*:}"
}
