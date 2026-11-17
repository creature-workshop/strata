#!/bin/sh

: <<'MODULE'
silt__text_starts_with: a predicate that answers true when the text at a
path of a member starts with a prefix.
MODULE

: <<'PUB_FUN'
The plumbing of @text_starts_with: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_text_starts_with.sh documents it.
PUB_FUN
silt__text_starts_with() {
  __silt__out "$1" || return 1
  __silt__text_starts_with__out="$__silt__OUT"

  __silt__text_starts_with__held=''
  silt__string __silt__text_starts_with__held "$2" "$3" || return 1
  case "$__silt__text_starts_with__held" in
    "${4:-}"*) __silt__ANSWER=true ;;
    *) __silt__ANSWER=false ;;
  esac

  __silt__OUT="$__silt__text_starts_with__out"
  __silt__answer
}
