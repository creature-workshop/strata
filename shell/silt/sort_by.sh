#!/bin/sh

: <<'MODULE'
silt__sort_by: a list with its elements in the order of the values at paths
inside them.
MODULE

: <<'PUB_FUN'
Answers the list with its elements in the order of the value at a path
inside each, renumbered from 0. Given several paths, orders by the value at
the first path, and orders the elements that tie there by the value at the
next. Given no path, orders by the elements themselves. Elements that tie
at every path keep the order the list holds them in.

Values are ordered by kind first: a null or a path that holds nothing, then
false, then true, then a number, then a text. Numbers are ordered by size.
Texts are ordered byte by byte, a str read as the text it spells. Refuses a
document that is not a list, and a map or a list at a path. This runs in
awk whatever the list's size.

  silt__sort_by doc '0.0:map
  1."at":int=2
  0.1:map
  1."at":int=1' .at   ->  doc='0.0:map
                               1."at":int=1
                               0.1:map
                               1."at":int=2'

  silt__sort_by queue "$queue" .ready_at .iid   ->  by ready_at, then by iid

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
silt__sort_by() {
  __silt__out "$1" || return 1
  __silt__sort_by__out="$__silt__OUT"
  shift

  __silt__hand_keyed sort_by "$@" || return 1

  __silt__OUT="$__silt__sort_by__out"
  __silt__answer
}
