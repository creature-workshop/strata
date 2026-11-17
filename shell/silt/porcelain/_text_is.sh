#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/text_is.sh: @text_is.
FRAGMENT

: <<'PUB_FUN'
A predicate for @filter, @find, @any and @all. Answers
true when the text at a path of the member is the text given, and false
otherwise.

The text at a path is what @string answers: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
that holds nothing or holds a collection. The path "." is the member
itself.

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

  names="$(cat <<'SILT'
  0.0:str="build"
  0.1:str=""
  0.2:str="test"
  SILT
  )"
  @filter builds "$names" @text_is . build   ->  builds='0.0:str="build"'

  The same, with each SILT document written as JSON:

    @filter builds ["build","","test"] @text_is . build   ->  builds=["build"]

  Called directly, as a verb calls it:

  @text_is yes '0."status":str="passed"' .status passed   ->  yes=true
  @text_is yes '0."status":str="passed"' .status failed   ->  yes=false

  The same, with each SILT document written as JSON:

    @text_is yes {"status":"passed"} .status passed   ->  yes=true
    @text_is yes {"status":"passed"} .status failed   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The member's value, a SILT document
  $3  The path
  $4  The text to compare with; the empty string when not given
PUB_FUN
@text_is() {
  silt__text_is "$@"
}
