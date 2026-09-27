#!/bin/sh

: <<'MODULE'
silt__unique: a list with its repeated values dropped.
MODULE

: <<'PUB_FUN'
Answers the list with every element that is the same value as an earlier
one dropped, the rest in their order and renumbered from 0. Two elements
are the same value when silt__equals says so, a map in either order among
them. This runs in awk whatever the list's size.

  silt__unique doc '0.0:int=1
  0.1:int=2
  0.2:int=1'   ->  doc='0.0:int=1
  0.1:int=2'

args:
  $1  The name of the variable to answer in
  $2  The list
PUB_FUN
silt__unique() {
  __silt__out "$1" || return 1
  __silt__unique__out="$__silt__OUT"

  __silt__require_list "$2" unique || return 1
  __silt__ANSWER=''
  __silt__hand_off "$2" 'order elements unique' || return 1

  __silt__OUT="$__silt__unique__out"
  __silt__answer
}
