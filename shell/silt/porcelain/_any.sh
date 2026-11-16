#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/any.sh: @any.
FRAGMENT

: <<'PUB_FUN'
Answers true when the predicate answers true for some member, and false
otherwise, the empty collection included. The walk ends at the first member
taken. The predicate is called the way @filter calls one.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @any failing "$tests" @text_is .status failed   ->  failing=true

  The same, with each SILT document written as JSON:

    @any failing [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] @text_is .status failed   ->  failing=true

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
@any() {
  silt__any "$@"
}
