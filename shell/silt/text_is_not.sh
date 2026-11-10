#!/bin/sh

: <<'MODULE'
silt__text_is_not: a predicate that answers true when the text at a path
of a member differs from a text.
MODULE

: <<'PUB_FUN'
A predicate for silt__filter, silt__find, silt__any and silt__all. Answers
true when the text at a path of the member differs from the text given, and
false when the two are the same. It reads the text as silt__text_is does,
so a path that holds nothing has the empty text.

  silt__filter failing "$tests" silt__text_is_not .status passed
  silt__filter named "$names" silt__text_is_not . ''

  silt__text_is_not no 0 '0."status":str="passed"' .status passed   ->  no=false
  silt__text_is_not no 0 '0."status":str="passed"' .status failed   ->  no=true

args:
  $1  The name of the variable to answer in
  $2  The member's key, which this predicate does not read
  $3  The member's value, a document
  $4  The path
  $5  The text to compare with; the empty string when not given
PUB_FUN
silt__text_is_not() {
  __silt__out "$1" || return 1
  __silt__text_is_not__out="$__silt__OUT"

  __silt__text_is_not__held=''
  silt__string __silt__text_is_not__held "$3" "$4" || return 1
  if [ "$__silt__text_is_not__held" = "${5:-}" ]; then
    __silt__ANSWER=false
  else
    __silt__ANSWER=true
  fi

  __silt__OUT="$__silt__text_is_not__out"
  __silt__answer
}
