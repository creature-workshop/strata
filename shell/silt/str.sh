#!/bin/sh

: <<'MODULE'
silt__str: builds a str document from text.
MODULE

: <<'PUB_FUN'
The plumbing of @str: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_str.sh documents it.
PUB_FUN
silt__str() {
  __silt__out "$1" || return 1
  __silt__str__out="$__silt__OUT"

  __silt__wrap_literal "$2"

  __silt__ANSWER="0.:str=$__silt__LITERAL"
  __silt__OUT="$__silt__str__out"
  __silt__answer
}
