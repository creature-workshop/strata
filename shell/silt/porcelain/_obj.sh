#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/obj.sh: @obj.
FRAGMENT

: <<'PUB_FUN'
Builds a map from key and document pairs, in the order given. With no pairs
it builds the empty map. A key is plain text; the map quotes it. Members are
appended as given, so a key given twice appears twice; @set is what
replaces a member.

  @obj doc runner '0.:str="bats"' count '0.:int=3'

  doc is:
    0."runner":str="bats"
    0."count":int=3

  The same, with each SILT document written as JSON:

    @obj doc runner "bats" count 3   ->  doc={"runner":"bats","count":3}

args:
  $1  The name of the variable to answer in
  $@  A key and a SILT document, pair by pair
PUB_FUN
@obj() {
  silt__obj "$@"
}
