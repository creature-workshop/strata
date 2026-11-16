#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/concat.sh: @concat.
FRAGMENT

: <<'PUB_FUN'
Appends the second list's elements to the first, renumbering them to carry
on from the first list's count.

  @concat doc '0.0:str="a"' '0.0:str="b"'

  doc is:
    0.0:str="a"
    0.1:str="b"

  The same, with each SILT document written as JSON:

    @concat doc ["a"] ["b"]   ->  doc=["a","b"]

args:
  $1  The name of the variable to answer in
  $2  The first list
  $3  The second list
PUB_FUN
@concat() {
  silt__concat "$@"
}
