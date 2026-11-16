#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/keys.sh: @keys.
FRAGMENT

: <<'PUB_FUN'
Answers the members' keys as a list document: a map's as str leaves holding
the key literals in the order they sit, a list's as int leaves.

  map="$(cat <<'SILT'
  0."b":int=1
  0."a":int=2
  SILT
  )"
  @keys names "$map"

  names is:
    0.0:str="b"
    0.1:str="a"

  The same, with each SILT document written as JSON:

    @keys names {"b":1,"a":2}   ->  names=["b","a"]

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@keys() {
  silt__keys "$@"
}
