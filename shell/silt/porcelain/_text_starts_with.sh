#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/text_starts_with.sh: @text_starts_with.
FRAGMENT

: <<'PUB_FUN'
A predicate for @filter, @find, @any and @all. Answers
true when the text at a path of the member starts with the prefix given,
and false otherwise. It reads the text as @text_is does. Every text
starts with the empty prefix, the empty text among them.

  labels="$(cat <<'SILT'
  0.0:str="area/lib"
  0.1:str="type/fix"
  0.2:str="area/cli"
  SILT
  )"
  @filter areas "$labels" @text_starts_with . area/

  areas is:
    0.0:str="area/lib"
    0.1:str="area/cli"

  The same, with each SILT document written as JSON:

    @filter areas ["area/lib","type/fix","area/cli"] @text_starts_with . area/   ->  areas=["area/lib","area/cli"]

  Called directly, as a verb calls it:

  @text_starts_with yes 0 '0.:str="area/lib"' . area/   ->  yes=true
  @text_starts_with yes 0 '0.:str="type/fix"' . area/   ->  yes=false

  The same, with each SILT document written as JSON:

    @text_starts_with yes 0 "area/lib" . area/   ->  yes=true
    @text_starts_with yes 0 "type/fix" . area/   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The member's key, which this predicate does not read
  $3  The member's value, a SILT document
  $4  The path
  $5  The prefix; the empty string when not given
PUB_FUN
@text_starts_with() {
  silt__text_starts_with "$@"
}
