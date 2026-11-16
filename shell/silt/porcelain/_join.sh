#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/join.sh: @join.
FRAGMENT

: <<'PUB_FUN'
Joins a list's elements into one text, with the separator between them.
Each element is read the way @string reads it: a str unquoted, another
scalar as written, null as the word null. Refuses a list that holds a
collection.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @join text "$list" ', '   ->  text='a, b'

  The same, with each SILT document written as JSON:

    @join text ["a","b"] ', '   ->  text='a, b'

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The separator; empty when omitted
PUB_FUN
@join() {
  silt__join "$@"
}
