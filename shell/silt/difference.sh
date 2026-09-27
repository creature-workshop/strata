#!/bin/sh

: <<'MODULE'
silt__difference: the elements of one list that another does not hold.
MODULE

: <<'PUB_FUN'
Answers the elements of the first list whose value the second list holds
nowhere, in their order and renumbered from 0. Two elements are the same
value when silt__equals says so. This runs in awk whatever the lists' size,
the second list reaching it through the spill file.

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
  __silt__against_spilled "$2" "$3" 'order elements difference' || return 1

  __silt__OUT="$__silt__difference__out"
  __silt__answer
}

: <<'FUN'
Runs awk programs over one document on stdin with a second in the spill
file, and takes what they print as the answer. The spill file is removed
whether or not the programs refuse.

args:
  $1  The document for stdin
  $2  The document for the spill file
  $3  The programs' names under shell/silt/awk, separated by spaces
FUN
__silt__against_spilled() {
  __silt__against_spilled__status=0
  __silt__ANSWER=''
  __silt__spill "$2"
  __silt__hand_off "$1" "$3" || __silt__against_spilled__status=$?
  __silt__unspill

  return "$__silt__against_spilled__status"
}
