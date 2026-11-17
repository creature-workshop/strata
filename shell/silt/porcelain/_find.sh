#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/find.sh: @find, @findi and @findk.
FRAGMENT

: <<'PUB_FUN'
Answers the value of the first member the predicate answers true for, as a
document of its own, and the empty string, which is not a SILT document,
when it takes none. The walk ends at that member. The predicate is called
the way @filter calls one.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @find failed "$tests" @text_is .status failed

  failed is:
    0."name":str="lint"
    0."status":str="failed"

  The same, with each SILT document written as JSON:

    @find failed [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] @text_is .status failed   ->  failed={"name":"lint","status":"failed"}

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the value
PUB_FUN
@find() {
  silt__find "$@"
}

: <<'PUB_FUN'
Answers what @find answers. The predicate is called the way @filteri calls
one: it also receives the member's position, counted from 0, after the
value.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  from_position() { @succeeds "$1" [ "$3" -ge "$4" ]; }
  @findi second "$tests" from_position 1

  second is:
    0."name":str="lint"
    0."status":str="failed"

  The same, with each SILT document written as JSON:

    @findi second [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] from_position 1   ->  second={"name":"lint","status":"failed"}

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the index
PUB_FUN
@findi() {
  silt__findi "$@"
}

: <<'PUB_FUN'
Answers what @find answers. The predicate is called the way @filterk calls
one: it also receives the member's key, as plain text, after the value.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  key_is() { @succeeds "$1" [ "$3" = "$4" ]; }
  @findk count "$counts" key_is b   ->  count='0.:int=2'

  The same, with each SILT document written as JSON:

    @findk count {"a":1,"b":2} key_is b   ->  count=2

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key
PUB_FUN
@findk() {
  silt__findk "$@"
}
