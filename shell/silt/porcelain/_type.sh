#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/type.sh: @type.
FRAGMENT

: <<'PUB_FUN'
Answers what kind of value a SILT document is: map or list from the key of its
first member, else the type of its one keyless line. Given a path, answers
the kind of the value at that path, and the empty string when the path
holds nothing.

  @type kind '0."a":int=1'      ->  kind=map
  @type kind '0.0:int=1'        ->  kind=list
  @type kind '0.:str="x"'       ->  kind=str
  @type kind '0."a":int=1' .a   ->  kind=int
  @type kind '0."a":int=1' .b   ->  kind=

  The same, with each SILT document written as JSON:

    @type kind {"a":1}   ->  kind=map
    @type kind [1]   ->  kind=list
    @type kind "x"   ->  kind=str
    @type kind {"a":1} .a   ->  kind=int
    @type kind {"a":1} .b   ->  kind=

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $3  The path, when given
PUB_FUN
@type() {
  silt__type "$@"
}
