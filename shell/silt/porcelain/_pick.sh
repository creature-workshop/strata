#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/pick.sh: @pick, @without.
FRAGMENT

: <<'PUB_FUN'
Answers the map with only the members under the keys given, in the map's own
order. A key that the map does not hold is left out. Refuses a SILT document
that is not a map.

  map="$(cat <<'SILT'
  0."title":str="t"
  0."token":str="s"
  0."body":str="b"
  SILT
  )"
  @pick doc "$map" title body

  doc is:
    0."title":str="t"
    0."body":str="b"

  The same, with each SILT document written as JSON:

    @pick doc {"title":"t","token":"s","body":"b"} title body   ->  doc={"title":"t","body":"b"}

args:
  $1  The name of the variable to answer in
  $2  The map
  $@  The keys to keep
PUB_FUN
@pick() {
  silt__pick "$@"
}

: <<'PUB_FUN'
Answers the map without the members under the keys given. Use it to take a
secret out of a map before the map is logged. Refuses a SILT document that is
not a map.

  map="$(cat <<'SILT'
  0."title":str="t"
  0."token":str="s"
  SILT
  )"
  @without doc "$map" token   ->  doc='0."title":str="t"'

  The same, with each SILT document written as JSON:

    @without doc {"title":"t","token":"s"} token   ->  doc={"title":"t"}

args:
  $1  The name of the variable to answer in
  $2  The map
  $@  The keys to leave out
PUB_FUN
@without() {
  silt__without "$@"
}
