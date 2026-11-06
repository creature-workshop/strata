#!/bin/sh

: <<'MODULE'
silt__difference: the elements of one list that another does not hold.
MODULE

: <<'PUB_FUN'
Answers the elements of the first list whose value the second list holds
nowhere, in their order and renumbered from 0. Two elements are the same
value when silt__equals says so. This runs in awk whatever the lists' size.

  silt__difference doc '0.0:int=1
  0.1:int=2' '0.0:int=2'   ->  doc='0.0:int=1'

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The list whose values are taken out
PUB_FUN
silt__difference() {
  __silt__out "$1" || return 1
  __silt__difference__out="$__silt__OUT"

  __silt__require_list "$2" difference || return 1
  __silt__require_list "$3" difference || return 1
  __silt__hand_off_with "$2" "$3" 'order elements difference' || return 1

  __silt__OUT="$__silt__difference__out"
  __silt__answer
}

