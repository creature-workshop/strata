#!/bin/sh

: <<'MODULE'
silt__text_is_not: a predicate that answers true when the text at a path
of a member differs from a text.
MODULE

: <<'PUB_FUN'
The plumbing of @text_is_not: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_text_is_not.sh documents it.
PUB_FUN
silt__text_is_not() {
  __silt__out "$1" || return 1
  __silt__text_is_not__out="$__silt__OUT"

  __silt__text_is_not__held=''
  silt__string __silt__text_is_not__held "$2" "$3" || return 1
  if [ "$__silt__text_is_not__held" = "${4:-}" ]; then
    __silt__ANSWER=false
  else
    __silt__ANSWER=true
  fi

  __silt__OUT="$__silt__text_is_not__out"
  __silt__answer
}
