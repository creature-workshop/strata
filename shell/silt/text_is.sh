#!/bin/sh

: <<'MODULE'
silt__text_is: a predicate that compares the text at a path of a member
with a text.
MODULE

: <<'PUB_FUN'
The plumbing of @text_is: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_text_is.sh documents it.
PUB_FUN
silt__text_is() {
  __silt__out "$1" || return 1
  __silt__text_is__out="$__silt__OUT"

  __silt__text_is__held=''
  silt__string __silt__text_is__held "$3" "$4" || return 1
  __silt__is_spelled "$__silt__text_is__held" "${5:-}"

  __silt__OUT="$__silt__text_is__out"
  __silt__answer
}
