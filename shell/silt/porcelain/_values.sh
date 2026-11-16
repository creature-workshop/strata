#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/values.sh: @values.
FRAGMENT

: <<'PUB_FUN'
Answers the values a map holds as a list, in the order the map holds them,
numbered from 0. A list answers itself. The empty map answers the empty
list. Refuses a SILT document that is neither a map nor a list.

  map="$(cat <<'SILT'
  0."a":int=1
  0."b":map
  1."c":int=2
  SILT
  )"
  @values doc "$map"

  doc is:
    0.0:int=1
    0.1:map
    1."c":int=2

  The same, with each SILT document written as JSON:

    @values doc {"a":1,"b":{"c":2}}   ->  doc=[1,{"c":2}]

args:
  $1  Name of the variable that receives the result
  $2  The map
PUB_FUN
@values() {
  silt__values "$@"
}
