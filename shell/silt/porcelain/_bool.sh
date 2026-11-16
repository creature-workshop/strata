#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/bool.sh: @bool, @null.
FRAGMENT

: <<'PUB_FUN'
Builds a bool document from the word true or the word false. Refuses any
other word.

  @bool doc true   ->  doc='0.:bool=true'

  The same, with each SILT document written as JSON:

    @bool doc true   ->  doc=true

args:
  $1  The name of the variable to answer in
  $2  true or false
PUB_FUN
@bool() {
  silt__bool "$@"
}

: <<'PUB_FUN'
Builds the null document. A null is a value that a record holds on purpose.
It is different from a field that is missing.

  @null doc   ->  doc='0.:null'

  The same, with each SILT document written as JSON:

    @null doc   ->  doc=null

args:
  $1  The name of the variable to answer in
PUB_FUN
@null() {
  silt__null "$@"
}
