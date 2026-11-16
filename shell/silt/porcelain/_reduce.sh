#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/reduce.sh: @reduce.
FRAGMENT

: <<'PUB_FUN'
Answers the value that a callback builds from the members of a map or a
list. The callback is called once for each member, in order. It receives
the value built so far and answers the next one. The value starts as the
empty list, or as the SILT document after --from.

The callback is called with the name of the variable to answer in, the
member's key as text, its value as a document, the value built so far, and
the extra arguments after them. It can run any verb, a loop of its own
included.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  add_length() { @len n "$3"; @scalar so_far "$4"; @read "$1" "$((so_far + n))"; }
  @reduce total "$tests" add_length --from '0.:int=0'   ->  total='0.:int=4'

  The same, with each SILT document written as JSON:

    @reduce total [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] add_length --from 0   ->  total=4

  The callback is called as:

  callback <out> <key> <value> <so far> [extras...]  ->  answers a document in <out>

args:
  $1      The name of the variable to answer in
  $2      The SILT document, a map or a list
  $3      The callback
  --from  The SILT document the value starts as; the empty list when not given
  $@      Extra arguments the callback receives after the value built so far
PUB_FUN
@reduce() {
  silt__reduce "$@"
}
