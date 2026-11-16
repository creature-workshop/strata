#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/defined.sh: @defined, @empty.
FRAGMENT

: <<'PUB_FUN'
Answers true when the value is a SILT document and is not a null. Answers
false for a null and for the empty string, which is what @get answers for a
path that holds nothing.

  @defined yes '0.:int=0'   ->  yes=true
  @defined yes '0.:null'    ->  yes=false

  The same, with each SILT document written as JSON:

    @defined yes 0   ->  yes=true
    @defined yes null   ->  yes=false

  @defined yes ''           ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The value, a SILT document or the empty string
PUB_FUN
@defined() {
  silt__defined "$@"
}

: <<'PUB_FUN'
Answers true when a map or a list has no members, and false when it has
any. Refuses every other value: a scalar, a null and the empty string are
not collections, so a missing value is never reported as an empty one.

  @empty none '0.:list'               ->  none=true
  @empty none '0."name":str="lib"'    ->  none=false, a map with one member
  @empty none '0.0:int=1'             ->  none=false, a list with one element
  @empty none '0.:int=1'              ->  refused: an int is not a map or a list

  The same, with each SILT document written as JSON:

    @empty none []   ->  none=true
    @empty none {"name":"lib"}   ->  none=false, a map with one member
    @empty none [1]   ->  none=false, a list with one element
    @empty none 1   ->  refused: an int is not a map or a list

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
PUB_FUN
@empty() {
  silt__empty "$@"
}
