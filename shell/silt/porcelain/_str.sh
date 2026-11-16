#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/str.sh: @str.
FRAGMENT

: <<'PUB_FUN'
Builds a str document from text, quoted and escaped the way JSON writes a
string.

  @str doc 'lib/a.sh'   ->  doc='0.:str="lib/a.sh"'

  The same, with each SILT document written as JSON:

    @str doc 'lib/a.sh'   ->  doc="lib/a.sh"

args:
  $1  The name of the variable to answer in
  $2  The text
PUB_FUN
@str() {
  silt__str "$@"
}
