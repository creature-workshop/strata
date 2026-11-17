#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/reduce.sh: @reduce, @reducei and @reducek.
FRAGMENT

: <<'PUB_FUN'
Answers the value that a callback builds from the members of a map or a
list. The callback is called once for each member, in order. It receives
the value built so far and answers the next one. The value starts as the
empty list, or as the SILT document after --from.

The callback is called with the name of the variable to answer in, the
value built so far, the member's value as a SILT document, and the extra
arguments after them. It can run any verb, a loop of its own included.
When the callback fails, the verb stops and returns the callback's status.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  add_length() { @scalar so_far "$2"; @len n "$3"; @read "$1" "$((so_far + n))"; }
  @reduce total "$tests" add_length --from '0.:int=0'   ->  total='0.:int=4'

  The same, with each SILT document written as JSON:

    @reduce total [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] add_length --from 0   ->  total=4

  The callback is called as:

  callback <out> <so far> <value> [extras...]  ->  answers a document in <out>

args:
  $1      The name of the variable to answer in
  $2      The SILT document, a map or a list
  $3      The callback
  --from  The SILT document the value starts as; the empty list when not given
  $@      Extra arguments the callback receives after the member's value
PUB_FUN
@reduce() {
  silt__reduce "$@"
}

: <<'PUB_FUN'
Answers what @reduce answers. The callback also receives the member's
position, counted from 0, after the member's value. A member of a map has
a position too: the first member is at 0.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  add_position() { @scalar so_far "$2"; @read "$1" "$((so_far + $4))"; }
  @reducei sum "$tests" add_position --from '0.:int=0'   ->  sum='0.:int=1'

  The same, with each SILT document written as JSON:

    @reducei sum [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] add_position --from 0   ->  sum=1

  The callback is called as:

  callback <out> <so far> <value> <index> [extras...]  ->  answers a document in <out>

args:
  $1      The name of the variable to answer in
  $2      The SILT document, a map or a list
  $3      The callback
  --from  The SILT document the value starts as; the empty list when not given
  $@      Extra arguments the callback receives after the index
PUB_FUN
@reducei() {
  silt__reducei "$@"
}

: <<'PUB_FUN'
Answers what @reduce answers. The callback also receives the member's key
after the member's value. The key is plain text, not a SILT document: a
map's key without its quotes, and for a list the member's index. @member
reads the member back from the key.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  collect_key() { @str key "$4"; @push "$1" "$2" "$key"; }
  @reducek keys "$counts" collect_key

  keys is:
    0.0:str="a"
    0.1:str="b"

  The same, with each SILT document written as JSON:

    @reducek keys {"a":1,"b":2} collect_key   ->  keys=["a","b"]

  The callback is called as:

  callback <out> <so far> <value> <key> [extras...]  ->  answers a document in <out>

args:
  $1      The name of the variable to answer in
  $2      The SILT document, a map or a list
  $3      The callback
  --from  The SILT document the value starts as; the empty list when not given
  $@      Extra arguments the callback receives after the key
PUB_FUN
@reducek() {
  silt__reducek "$@"
}
