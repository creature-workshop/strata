#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/entries.sh: @entries.
FRAGMENT

: <<'PUB_FUN'
Answers a map as a list with one element per member, in the order the map
holds them. Each element is a map of two members: "key", the member's key
as a str, and "value", the member's value. The empty map answers the empty
list. Refuses a SILT document that is not a map.

  map="$(cat <<'SILT'
  0."a":int=1
  0."b":list
  1.0:int=2
  SILT
  )"
  @entries doc "$map"

  doc is:
    0.0:map
    1."key":str="a"
    1."value":int=1
    0.1:map
    1."key":str="b"
    1."value":list
    2.0:int=2

  The same, with each SILT document written as JSON:

    @entries doc {"a":1,"b":[2]}   ->  doc=[{"key":"a","value":1},{"key":"b","value":[2]}]

args:
  $1  Name of the variable that receives the result
  $2  The map
PUB_FUN
@entries() {
  silt__entries "$@"
}
