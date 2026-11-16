#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/sort.sh: @sort.
FRAGMENT

: <<'PUB_FUN'
Returns the list with its elements in the order of their values,
renumbered from 0. Elements that are the same value keep the order the
list has them in.

Values are ordered by kind first: null, then false, then true, then
numbers, then texts, then lists, then maps. Numbers are ordered by size.
Texts are ordered byte by byte, with a str read as the text it stands for.
Two lists are compared element by element, and the shorter one comes first
when one is the start of the other. Two maps are compared by their sorted
keys first, and then by their values in that order. This is the order jq's
sort gives.

Fails when the SILT document is not a list. This runs in awk whatever the size
of the list.

  mixed="$(cat <<'SILT'
  0.0:str="b"
  0.1:int=2
  0.2:null
  SILT
  )"
  @sort doc "$mixed"

  doc is:
    0.0:null
    0.1:int=2
    0.2:str="b"

  The same, with each SILT document written as JSON:

    @sort doc ["b",2,null]   ->  doc=[null,2,"b"]

args:
  $1  The name of the variable that receives the result
  $2  The list
PUB_FUN
@sort() {
  silt__sort "$@"
}
