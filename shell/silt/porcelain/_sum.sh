#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/sum.sh: @sum.
FRAGMENT

: <<'PUB_FUN'
Answers the sum of a list of numbers as a number document. A list of whole
numbers is added in the shell and answers an int. A list that holds a
number with a fraction is added in awk and answers a float. The empty list
answers the int 0. Refuses a SILT document that is not a list, and a list that
holds anything but numbers.

  list="$(cat <<'SILT'
  0.0:int=1
  0.1:int=2
  SILT
  )"
  @sum total "$list"   ->  total='0.:int=3'

  The same, with each SILT document written as JSON:

    @sum total [1,2]   ->  total=3

  list="$(cat <<'SILT'
  0.0:int=1
  0.1:float=1.5
  SILT
  )"
  @sum total "$list"   ->  total='0.:float=2.5'

  The same, with each SILT document written as JSON:

    @sum total [1,1.5]   ->  total=2.5

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
@sum() {
  silt__sum "$@"
}
