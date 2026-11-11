#!/bin/sh

: <<'MODULE'
silt__group_by: a list's elements gathered into lists of the ones that hold
the same values at paths inside them.
MODULE

: <<'PUB_FUN'
Answers a list of lists. Each inner list holds the elements whose values at
the path are the same, in the order the list holds them. The inner lists
are in the order of those values, as silt__sort_by orders them. Given
several paths, two elements are in the same inner list when their values
are the same at every path. Given no path, the elements themselves are
compared. The empty list answers the empty list. Refuses a document that is
not a list, and a map or a list at a path. This runs in awk whatever the
list's size.

  silt__group_by doc '0.0:str="b"
  0.1:str="a"
  0.2:str="b"'   ->  doc='0.0:list
                          1.0:str="a"
                          0.1:list
                          1.0:str="b"
                          1.1:str="b"'

  silt__group_by by_suite "$rows" .suite   ->  one list of rows for each suite

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
silt__group_by() {
  __silt__out "$1" || return 1
  __silt__group_by__out="$__silt__OUT"
  shift

  __silt__hand_keyed group_by "$@" || return 1

  __silt__OUT="$__silt__group_by__out"
  __silt__answer
}
