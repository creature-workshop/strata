#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/map.sh: @map, @mapi and @mapk.
FRAGMENT

: <<'PUB_FUN'
Answers a SILT document of the same kind as the one given, each member's value
replaced by the document the callback answers for it: a map keeps its keys,
a list its indices. The callback is called with the name of the variable to
answer in, the member's value as a SILT document, and the extra arguments
after it. It can run any verb, a loop of its own included. When the
callback fails, the verb stops and returns the callback's status.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  name_of() { @get "$1" "$2" .name; }
  @map names "$tests" name_of

  names is:
    0.0:str="build"
    0.1:str="lint"

  The same, with each SILT document written as JSON:

    @map names [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] name_of   ->  names=["build","lint"]

  The callback is called as:

  callback <out> <value> [extras...]  ->  answers a document in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The callback
  $@  Extra arguments the callback receives after the value
PUB_FUN
@map() {
  silt__map "$@"
}

: <<'PUB_FUN'
Answers what @map answers. The callback also receives the member's
position, counted from 0, after the value. A member of a map has a position
too: the first member is at 0.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  numbered() { @string name "$2" .name; @str "$1" "$3:$name"; }
  @mapi labels "$tests" numbered

  labels is:
    0.0:str="0:build"
    0.1:str="1:lint"

  The same, with each SILT document written as JSON:

    @mapi labels [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] numbered   ->  labels=["0:build","1:lint"]

  The callback is called as:

  callback <out> <value> <index> [extras...]  ->  answers a document in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The callback
  $@  Extra arguments the callback receives after the index
PUB_FUN
@mapi() {
  silt__mapi "$@"
}

: <<'PUB_FUN'
Answers what @map answers. The callback also receives the member's key
after the value. The key is plain text, not a SILT document: a map's key
without its quotes, and for a list the member's index. @member reads the
member back from the key.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  key_of() { @str "$1" "$3"; }
  @mapk named "$counts" key_of

  named is:
    0."a":str="a"
    0."b":str="b"

  The same, with each SILT document written as JSON:

    @mapk named {"a":1,"b":2} key_of   ->  named={"a":"a","b":"b"}

  The callback is called as:

  callback <out> <value> <key> [extras...]  ->  answers a document in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The callback
  $@  Extra arguments the callback receives after the key
PUB_FUN
@mapk() {
  silt__mapk "$@"
}
