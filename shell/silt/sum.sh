#!/bin/sh

: <<'MODULE'
silt__sum: the sum of a list of numbers.
MODULE

: <<'PUB_FUN'
Answers the sum of a list of numbers as a number document. A list of whole
numbers is added in the shell and answers an int. A list that holds a
number with a fraction is added in awk and answers a float. The empty list
answers the int 0. Refuses a document that is not a list, and a list that
holds anything but numbers.

  silt__sum total '0.0:int=1
  0.1:int=2'       ->  total='0.:int=3'
  silt__sum total '0.0:int=1
  0.1:float=1.5'   ->  total='0.:float=2.5'

registers:
  __silt__FRACTION  Whether the walk met a number with a fraction

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
silt__sum() {
  __silt__out "$1" || return 1
  __silt__sum__out="$__silt__OUT"

  __silt__require_list "$2" sum || return 1
  __silt__FRACTION=false
  __silt__ANSWER=''
  __silt__AWK='sum'
  __silt__walk "$2" __silt__sum_line || return 1
  __silt__sum_answer "$2" || return 1

  __silt__OUT="$__silt__sum__out"
  __silt__answer
}

: <<'FUN'
Turns what the walk left into the answer. A walk that went to awk left the
answer itself. A walk that met a fraction hands the list to awk now. Any
other walk left the whole-number total, which becomes an int document.

args:
  $1  The list
FUN
__silt__sum_answer() {
  if [ "$__silt__HANDED" = true ]; then
    return 0
  fi
  if [ "$__silt__FRACTION" = true ]; then
    __silt__ANSWER=''
    __silt__hand_off "$1" sum
    return
  fi
  __silt__ANSWER="0.:int=${__silt__ANSWER:-0}"
}

: <<'FUN'
Handles one line of the walk: an element's own line is added, and the
empty list's one line is passed over.

args:
  $1  The line
FUN
__silt__sum_line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__add_element "$1" ;;
  esac
}

: <<'FUN'
Adds one element to the total in __silt__ANSWER when it is a whole number.
A number with a fraction ends the walk, since the shell cannot add one.
Refuses an element that is not a number.

args:
  $1  The element's depth-0 line
FUN
__silt__add_element() {
  __silt__parse "$1" || return 1

  case "$__silt__TYPE" in
    int) __silt__ANSWER=$((${__silt__ANSWER:-0} + __silt__VALUE)) ;;
    float)
      __silt__FRACTION=true
      __silt__STOP=true
      ;;
    *)
      __silt__fail "sum takes numbers, not a $__silt__TYPE at index $__silt__KEY"
      return 1
      ;;
  esac
}
