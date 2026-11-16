#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/from_entries.sh: @from_entries.
FRAGMENT

: <<'PUB_FUN'
Answers a map with one member for each element of a list, the reverse of
@entries. Each element is a map that holds the member's key under
"key" and the member's value under "value". The key is a scalar, and its
text becomes the member's key. An element with no "value" gives a null. The
members are in the order of the elements. When two elements have the same
key, the member stays where the first put it and has the value of the last.
The empty list answers the empty map.

Refuses a SILT document that is not a list, an element that is not a map,
and an element whose "key" is missing, a null, a map or a list.

  list="$(cat <<'SILT'
  0.0:map
  1."key":str="a"
  1."value":int=1
  0.1:map
  1."key":str="b"
  1."value":list
  2.0:int=2
  SILT
  )"
  @from_entries doc "$list"

  doc is:
    0."a":int=1
    0."b":list
    1.0:int=2

  The same, with each SILT document written as JSON:

    @from_entries doc [{"key":"a","value":1},{"key":"b","value":[2]}]   ->  doc={"a":1,"b":[2]}

args:
  $1  The name of the variable to answer in
  $2  The list
PUB_FUN
@from_entries() {
  silt__from_entries "$@"
}
