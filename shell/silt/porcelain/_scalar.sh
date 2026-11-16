#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/scalar.sh: @scalar.
FRAGMENT

: <<'PUB_FUN'
Answers the value text of a scalar document: the JSON literal of a str, the
digits of an int, "true" or "false", and the empty string for a null or an
empty collection.

  @scalar text '0.:str="bats"'   ->  text='"bats"'
  @scalar text '0.:int=3'        ->  text=3

  The same, with each SILT document written as JSON:

    @scalar text "bats"   ->  text='"bats"'
    @scalar text 3   ->  text=3

args:
  $1  The name of the variable to answer in
  $2  The SILT document, one keyless line
PUB_FUN
@scalar() {
  silt__scalar "$@"
}
