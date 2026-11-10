#!/bin/sh

: <<'MODULE'
silt__text_is: a predicate that compares the text at a path of a member
with a text.
MODULE

: <<'PUB_FUN'
A predicate for silt__filter, silt__find, silt__any and silt__all. Answers
true when the text at a path of the member is the text given, and false
otherwise.

The text at a path is what silt__string answers: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
that holds nothing or holds a collection. The path "." is the member
itself.

  silt__filter passing "$tests" silt__text_is .status passed
  silt__filter builds "$names" silt__text_is . build

  silt__text_is yes 0 '0."status":str="passed"' .status passed   ->  yes=true
  silt__text_is yes 0 '0."status":str="passed"' .status failed   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The member's key, which this predicate does not read
  $3  The member's value, a document
  $4  The path
  $5  The text to compare with; the empty string when not given
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
