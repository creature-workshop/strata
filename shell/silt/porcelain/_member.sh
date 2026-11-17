#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/member.sh: @member.
FRAGMENT

: <<'PUB_FUN'
Answers the member of a map or a list that a key names, as a SILT document
of its own. The key is plain text, as @mapk and the other `k` forms pass it
to a callback: a map's key without its quotes, or a list's index. The key
can hold any character, a dot included, because the caller writes no path.

Answers the empty string, which is not a SILT document, when the map or
the list has no such member. Refuses a document that is not a map or a
list.

  counts="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  @member count "$counts" b   ->  count='0.:int=2'

  The same, with each SILT document written as JSON:

    @member count {"a":1,"b":2} b   ->  count=2

  results='0."test/a.bats":str="passed"'
  @member result "$results" test/a.bats   ->  result='0.:str="passed"'

  The same, with each SILT document written as JSON:

    @member result {"test/a.bats":"passed"} test/a.bats   ->  result="passed"

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @member first "$tests" 0

  first is:
    0."name":str="build"
    0."status":str="passed"

  The same, with each SILT document written as JSON:

    @member first [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] 0   ->  first={"name":"build","status":"passed"}

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $3  The key, as plain text
PUB_FUN
@member() {
  silt__member "$@"
}
