#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/truth.sh: @is_true, @is_false, @is_zero, @not.
FRAGMENT

: <<'PUB_FUN'
Answers true when the SILT document is the bool true, and false for any other
document: the bool false, a str spelling the word, a map, anything.

  @is_true yes '0.:bool=true'   ->  yes=true
  @is_true yes '0.:str="true"'  ->  yes=false

  The same, with each SILT document written as JSON:

    @is_true yes true   ->  yes=true
    @is_true yes "true"   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@is_true() {
  silt__is_true "$@"
}

: <<'PUB_FUN'
Answers true when the SILT document is the bool false, and false for any other
document: the bool true, a null, an empty str, anything.

  @is_false no '0.:bool=false'   ->  no=true

  The same, with each SILT document written as JSON:

    @is_false no false   ->  no=true

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@is_false() {
  silt__is_false "$@"
}

: <<'PUB_FUN'
Answers true when the SILT document is the int 0, and false for any other
document: the float 0.0, the int -0, the str spelling a zero, anything.

  @is_zero none '0.:int=0'   ->  none=true

  The same, with each SILT document written as JSON:

    @is_zero none 0   ->  none=true

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@is_zero() {
  silt__is_zero "$@"
}

: <<'PUB_FUN'
Answers the opposite of a bool document. Refuses every other value: the
bare word true or false, a null and the empty string are not bool
documents, so an unset variable is never read as false.

  @not off '0.:bool=true'   ->  off='0.:bool=false'

  The same, with each SILT document written as JSON:

    @not off true   ->  off=false

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a bool
PUB_FUN
@not() {
  silt__not "$@"
}
