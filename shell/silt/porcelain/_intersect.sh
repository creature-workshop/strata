#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/intersect.sh: @intersect.
FRAGMENT

: <<'PUB_FUN'
Answers the elements of the first list whose value the second list holds
somewhere, in their order and renumbered from 0, an element the first list
holds twice kept twice. Two elements are the same value when @equals
says so. This runs in awk whatever the lists' size.

  list="$(cat <<'SILT'
  0.0:int=1
  0.1:int=2
  SILT
  )"
  @intersect doc "$list" '0.0:int=2'   ->  doc='0.0:int=2'

  The same, with each SILT document written as JSON:

    @intersect doc [1,2] [2]   ->  doc=[2]

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The list whose values are kept
PUB_FUN
@intersect() {
  silt__intersect "$@"
}
