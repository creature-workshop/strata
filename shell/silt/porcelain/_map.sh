#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/map.sh: @map.
FRAGMENT

: <<'PUB_FUN'
Answers a SILT document of the same kind as the one given, each member's value
replaced by the document the callback answers for it: a map keeps its keys,
a list its indices. The callback is called with the name of the variable to
answer in, the member's key as text, its value as a document, and the extra
arguments after them. It can run any verb, a loop of its own included.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  key_of() { @str "$1" "$2"; }
  @map named "$counts" key_of

  named is:
    0."a":str="a"
    0."b":str="b"

  The same, with each SILT document written as JSON:

    @map named {"a":1,"b":2} key_of   ->  named={"a":"a","b":"b"}

  The callback is called as:

  callback <out> <key> <value> [extras...]  ->  answers a document in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The callback
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
@map() {
  silt__map "$@"
}
