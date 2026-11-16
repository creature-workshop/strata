#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/text.sh: @unwrap, @wrap.
FRAGMENT

: <<'PUB_FUN'
Answers the text a JSON string literal spells: the quotes off and every
escape decoded.

  @unwrap text '"lib/a.sh"'          ->  text=lib/a.sh
  @unwrap text '"a \"b\"\nc"'        ->  text=a "b"<newline>c

args:
  $1  The name of the variable to answer in
  $2  The literal, quotes included
PUB_FUN
@unwrap() {
  silt__unwrap "$@"
}

: <<'PUB_FUN'
Answers the JSON string literal that spells <text>: quoted, with the quote,
the backslash and every control character escaped, the four JSON names by
letter and the rest as \u00XX.

  @wrap literal 'a "b"'   ->  literal='"a \"b\""'

args:
  $1  The name of the variable to answer in
  $2  The text
PUB_FUN
@wrap() {
  silt__wrap "$@"
}
