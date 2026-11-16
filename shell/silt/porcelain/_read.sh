#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/read.sh: @read, @to_line, @from_line.
FRAGMENT

: <<'PUB_FUN'
Answers the SILT document a text spells, whichever way the text is written:

  as SILT                 the text itself
  as SILT on one line     the text with its newlines put back
  as JSON                 the JSON translated

A JSON scalar is read in the shell. JSON that holds a map or a list goes
through @from_json, which starts one awk. Fails, without a message,
when the text is none of the three; the empty string is none of them. The
caller decides what such text means.

  @read doc '{"a":[1]}'

  doc is:
    0."a":list
    1.0:int=1

  The same, with each SILT document written as JSON:

    @read doc '{"a":[1]}'   ->  doc={"a":[1]}

  @read doc '"bats"'      ->  doc='0.:str="bats"'

  The same, with each SILT document written as JSON:

    @read doc '"bats"'   ->  doc="bats"

  @read doc 'bats'        ->  fails

args:
  $1  Name of the variable that receives the result
  $2  The text
PUB_FUN
@read() {
  silt__read "$@"
}

: <<'PUB_FUN'
Answers the SILT document written on one line: every newline becomes the unit
separator. A caller that reads values a line at a time, one value per line,
can then carry a whole document as one of them. @from_line and
@read both read the line back.

  map="$(cat <<'SILT'
  0."a":list
  1.0:int=1
  SILT
  )"
  @to_line text "$map"   ->  text='0."a":list<US>1.0:int=1'

args:
  $1  Name of the variable that receives the result
  $2  The SILT document
PUB_FUN
@to_line() {
  silt__to_line "$@"
}

: <<'PUB_FUN'
Answers the SILT document that @to_line wrote on one line: every unit
separator becomes a newline again. A document that was never on one line
answers itself.

  @from_line doc '0."a":list<US>1.0:int=1'

  doc is:
    0."a":list
    1.0:int=1

args:
  $1  Name of the variable that receives the result
  $2  The SILT document on one line
PUB_FUN
@from_line() {
  silt__from_line "$@"
}
