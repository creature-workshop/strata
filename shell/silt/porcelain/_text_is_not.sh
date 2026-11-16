#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/text_is_not.sh: @text_is_not.
FRAGMENT

: <<'PUB_FUN'
A predicate for @filter, @find, @any and @all. Answers
true when the text at a path of the member differs from the text given, and
false when the two are the same. It reads the text as @text_is does,
so a path that holds nothing has the empty text.

  tests="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  SILT
  )"
  @filter failing "$tests" @text_is_not .status passed

  failing is:
    0.0:map
    1."name":str="lint"
    1."status":str="failed"

  The same, with each SILT document written as JSON:

    @filter failing [{"name":"build","status":"passed"},{"name":"lint","status":"failed"}] @text_is_not .status passed   ->  failing=[{"name":"lint","status":"failed"}]

  names="$(cat <<'SILT'
  0.0:str="build"
  0.1:str=""
  0.2:str="test"
  SILT
  )"
  @filter named "$names" @text_is_not . ''

  named is:
    0.0:str="build"
    0.1:str="test"

  The same, with each SILT document written as JSON:

    @filter named ["build","","test"] @text_is_not . ''   ->  named=["build","test"]

  Called directly, as a verb calls it:

  @text_is_not no 0 '0."status":str="passed"' .status passed   ->  no=false
  @text_is_not no 0 '0."status":str="passed"' .status failed   ->  no=true

  The same, with each SILT document written as JSON:

    @text_is_not no 0 {"status":"passed"} .status passed   ->  no=false
    @text_is_not no 0 {"status":"passed"} .status failed   ->  no=true

args:
  $1  The name of the variable to answer in
  $2  The member's key, which this predicate does not read
  $3  The member's value, a SILT document
  $4  The path
  $5  The text to compare with; the empty string when not given
PUB_FUN
@text_is_not() {
  silt__text_is_not "$@"
}
