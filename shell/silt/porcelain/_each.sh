#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/each.sh: @each.
FRAGMENT

: <<'PUB_FUN'
Calls a callback once for each member of a map or a list. The callback
receives the member's key as text (a map's key unquoted, a list's index),
the member's value as a SILT document of its own, and then the extra
arguments. Stops at the first call that returns non-zero, and returns that
status.

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
  count_members() { @len n "$2"; total=$((total + n)); }
  total=0
  @each "$tests" count_members   ->  total=4

  The same, with each SILT document written as JSON:

    @each [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] count_members   ->  total=4

args:
  $1  The SILT document
  $2  The callback
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
@each() {
  silt__each "$@"
}
