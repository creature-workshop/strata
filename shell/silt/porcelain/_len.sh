#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/len.sh: @len.
FRAGMENT

: <<'PUB_FUN'
Answers how many members a map or a list holds, how many characters a str
spells, and 0 for a null.

  map="$(cat <<'SILT'
  0."a":int=1
  0."b":map
  1."c":int=2
  SILT
  )"
  @len n "$map"   ->  n=2

  The same, with each SILT document written as JSON:

    @len n {"a":1,"b":{"c":2}}   ->  n=2

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@len() {
  silt__len "$@"
}
