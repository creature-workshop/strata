#!/bin/sh

: <<'MODULE'
silt__intersect: the elements of one list that another holds too.
MODULE

: <<'PUB_FUN'
Answers the elements of the first list whose value the second list holds
somewhere, in their order and renumbered from 0, an element the first list
holds twice kept twice. Two elements are the same value when silt__equals
says so. This runs in awk whatever the lists' size, the second list reaching
it through the spill file.

  silt__intersect doc '0.0:int=1
  0.1:int=2' '0.0:int=2'   ->  doc='0.0:int=2'

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The list whose values are kept
PUB_FUN
silt__intersect() {
  __silt__out "$1" || return 1
  __silt__intersect__out="$__silt__OUT"

  __silt__require_list "$2" intersect || return 1
  __silt__require_list "$3" intersect || return 1
  __silt__against_spilled "$2" "$3" 'order elements intersect' || return 1

  __silt__OUT="$__silt__intersect__out"
  __silt__answer
}
