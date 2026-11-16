#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/unique.sh: @unique.
FRAGMENT

: <<'PUB_FUN'
Answers the list with every element that is the same value as an earlier
one dropped, the rest in their order and renumbered from 0. Two elements
are the same value when @equals says so, a map in either order among
them. This runs in awk whatever the list's size.

  list="$(cat <<'SILT'
  0.0:int=1
  0.1:int=2
  0.2:int=1
  SILT
  )"
  @unique doc "$list"

  doc is:
    0.0:int=1
    0.1:int=2

  The same, with each SILT document written as JSON:

    @unique doc [1,2,1]   ->  doc=[1,2]

args:
  $1  The name of the variable to answer in
  $2  The list
PUB_FUN
@unique() {
  silt__unique "$@"
}
