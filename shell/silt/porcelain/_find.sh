#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/find.sh: @find.
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
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
@find() {
  silt__find "$@"
}
