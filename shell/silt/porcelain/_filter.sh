#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/filter.sh: @filter, @filteri and @filterk.
FRAGMENT

: <<'PUB_FUN'
Answers a SILT document of the same kind as the one given, holding the members
the predicate answers true for: a map's under their keys, a list's numbered
on from 0. The predicate is called with the name of the variable to answer
in, the member's value as a SILT document, and the extra arguments after
it. It answers true or false, and it can run any verb, a loop of its own
included. When the predicate fails, the verb stops and returns the
predicate's status.

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

  predicate <out> <value> [extras...]  ->  answers true or false in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the value
PUB_FUN
@filter() {
  silt__filter "$@"
}

: <<'PUB_FUN'
Answers what @filter answers. The predicate also receives the member's
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
  from_position() { @succeeds "$1" [ "$3" -ge "$4" ]; }
  @filteri later "$tests" from_position 1

  later is:
    0.0:map
    1."name":str="lint"
    1."status":str="failed"

  The same, with each SILT document written as JSON:

    @filteri later [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] from_position 1   ->  later=[{"name":"lint","status":"failed"}]

  The predicate is called as:

  predicate <out> <value> <index> [extras...]  ->  answers true or false in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the index
PUB_FUN
@filteri() {
  silt__filteri "$@"
}

: <<'PUB_FUN'
Answers what @filter answers. The predicate also receives the member's key
after the value. The key is plain text, not a SILT document: a map's key
without its quotes, and for a list the member's index.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  key_is() { @succeeds "$1" [ "$3" = "$4" ]; }
  @filterk only "$counts" key_is b   ->  only='0."b":int=2'

  The same, with each SILT document written as JSON:

    @filterk only {"a":1,"b":2} key_is b   ->  only={"b":2}

  The predicate is called as:

  predicate <out> <value> <key> [extras...]  ->  answers true or false in <out>

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key
PUB_FUN
@filterk() {
  silt__filterk "$@"
}
