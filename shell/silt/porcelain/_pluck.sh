#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/pluck.sh: @pluck.
FRAGMENT

: <<'PUB_FUN'
Answers a list holding, for each member in order, the value at the path
inside it, as a SILT document of its own; null where a member holds nothing at
the path.

  list="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  0.1:map
  1."name":str="test"
  SILT
  )"
  @pluck names "$list" .name

  names is:
    0.0:str="build"
    0.1:str="test"

  The same, with each SILT document written as JSON:

    @pluck names [{"name":"build"},{"name":"test"}] .name   ->  names=["build","test"]

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The path into each member
PUB_FUN
@pluck() {
  silt__pluck "$@"
}
