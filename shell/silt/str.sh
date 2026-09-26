#!/bin/sh

: <<'MODULE'
silt__str: a str document from text.
MODULE

: <<'PUB_FUN'
Answers the scalar document that holds <text> as a str, wrapped as JSON
spells it.

  silt__str doc 'lib/a.sh'   ->  doc='0.:str="lib/a.sh"'

args:
  $1  The name of the variable to answer in
  $2  The text
PUB_FUN
silt__str() {
  __silt__out "$1" || return 1
  __silt__str__out="$__silt__OUT"

  __silt__wrap_literal "$2"

  __silt__ANSWER="0.:str=$__silt__LITERAL"
  __silt__OUT="$__silt__str__out"
  __silt__answer
}
