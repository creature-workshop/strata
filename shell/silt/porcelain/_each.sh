#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/each.sh: @each, @eachi and @eachk.
FRAGMENT

: <<'PUB_FUN'
Calls a callback once for each member of a map or a list. The callback
receives the member's value as a SILT document of its own, and then the
extra arguments. Stops at the first call that returns non-zero, and returns
that status.

The callback can run any verb, including @each and the verbs built on
it, so loops can be nested.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  count_members() { @len n "$1"; total=$((total + n)); }
  total=0
  @each "$tests" count_members   ->  total=4

  The same, with each SILT document written as JSON:

    @each [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] count_members   ->  total=4

  The callback is called as:

  callback <value> [extras...]

args:
  $1  The SILT document
  $2  The callback
  $@  Extra arguments the callback receives after the value
PUB_FUN
@each() {
  silt__each "$@"
}

: <<'PUB_FUN'
Calls a callback once for each member of a map or a list, as @each does.
The callback also receives the member's position, counted from 0, after the
value. A member of a map has a position too: the first member is at 0.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  note_position() { @string name "$1" .name; seen="$seen $2:$name"; }
  seen=''
  @eachi "$tests" note_position   ->  seen=' 0:build 1:lint'

  The same, with each SILT document written as JSON:

    @eachi [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] note_position   ->  seen=' 0:build 1:lint'

  The callback is called as:

  callback <value> <index> [extras...]

args:
  $1  The SILT document
  $2  The callback
  $@  Extra arguments the callback receives after the index
PUB_FUN
@eachi() {
  silt__eachi "$@"
}

: <<'PUB_FUN'
Calls a callback once for each member of a map or a list, as @each does.
The callback also receives the member's key after the value. The key is
plain text, not a SILT document: a map's key without its quotes, and for a
list the member's index. @member reads the member back from the key.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  note_key() { @scalar n "$1"; seen="$seen $2=$n"; }
  seen=''
  @eachk "$counts" note_key   ->  seen=' a=1 b=2'

  The same, with each SILT document written as JSON:

    @eachk {"a":1,"b":2} note_key   ->  seen=' a=1 b=2'

  The callback is called as:

  callback <value> <key> [extras...]

args:
  $1  The SILT document
  $2  The callback
  $@  Extra arguments the callback receives after the key
PUB_FUN
@eachk() {
  silt__eachk "$@"
}
