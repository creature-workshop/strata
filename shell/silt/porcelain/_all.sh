#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/all.sh: @all.
FRAGMENT

: <<'PUB_FUN'
Answers true when the predicate answers true for every member, the empty
collection included, and false otherwise. The walk ends at the first member
refused. The predicate is called the way @filter calls one.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @all clean "$tests" @text_is .status passed   ->  clean=false

  The same, with each SILT document written as JSON:

    @all clean [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] @text_is .status passed   ->  clean=false

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
@all() {
  silt__all "$@"
}
