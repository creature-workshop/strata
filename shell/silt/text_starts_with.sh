#!/bin/sh

: <<'MODULE'
silt__text_starts_with: a predicate that answers true when the text at a
path of a member starts with a prefix.
MODULE

: <<'PUB_FUN'
A predicate for silt__filter, silt__find, silt__any and silt__all. Answers
true when the text at a path of the member starts with the prefix given,
and false otherwise. It reads the text as silt__text_is does. Every text
starts with the empty prefix, the empty text among them.

  silt__filter areas "$labels" silt__text_starts_with . area/

  silt__text_starts_with yes 0 '0.:str="area/lib"' . area/   ->  yes=true
  silt__text_starts_with yes 0 '0.:str="type/fix"' . area/   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The member's key, which this predicate does not read
  $3  The member's value, a document
  $4  The path
  $5  The prefix; the empty string when not given
PUB_FUN
silt__text_starts_with() {
  __silt__out "$1" || return 1
  __silt__text_starts_with__out="$__silt__OUT"

  __silt__text_starts_with__held=''
  silt__string __silt__text_starts_with__held "$3" "$4" || return 1
  case "$__silt__text_starts_with__held" in
    "${5:-}"*) __silt__ANSWER=true ;;
    *) __silt__ANSWER=false ;;
  esac

  __silt__OUT="$__silt__text_starts_with__out"
  __silt__answer
}
