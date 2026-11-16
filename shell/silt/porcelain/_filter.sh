#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/filter.sh: @filter.
FRAGMENT

: <<'PUB_FUN'
Answers a SILT document of the same kind as the one given, holding the members
the predicate answers true for: a map's under their keys, a list's numbered
on from 0. The predicate is called with the name of the variable to answer
in, the member's key as text, its value as a document, and the extra
arguments after them. It answers true or false, and it can run any verb, a
loop of its own included.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @filter passing "$tests" @text_is .status passed

  passing is:
    0.0:map
    1."name":str="build"
    1."status":str="passed"

  The same, with each SILT document written as JSON:

    @filter passing [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] @text_is .status passed   ->  passing=[{"name":"build","status":"passed"}]

  The predicate is called as:

  predicate <out> <key> <value> [extras...]  ->  answers true or false in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
@filter() {
  silt__filter "$@"
}
