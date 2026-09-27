#!/bin/sh

: <<'MODULE'
Calling a caller's callback on a member, the way the verbs over each do: with
the name of the variable to answer in, the member's key and value, then the
caller's extra arguments.
MODULE

: <<'FUN'
Calls the callback on a member: the answer variable's name, the key, the
value and the extras, in that order. The callback may run any verb but each
and the verbs over it, so a verb keeps what it needs afterwards out of the
registers the reader and writer verbs write.

  __silt__ask __silt__MAPPED runner '0.:str="bats"' key_of tag
    ->  key_of __silt__MAPPED runner '0.:str="bats"' tag

args:
  $1  The name of the variable the callback answers in
  $2  The key, as text
  $3  The value, a document
  $4  The callback
  $@  The extras
FUN
__silt__ask() {
  __silt__ask__out="$1"
  __silt__ask__key="$2"
  __silt__ask__value="$3"
  __silt__ask__callback="$4"
  shift 4

  "$__silt__ask__callback" "$__silt__ask__out" "$__silt__ask__key" "$__silt__ask__value" "$@"
}

: <<'FUN'
Calls a predicate on a member and leaves its answer, true or false, in
__silt__VERDICT. Refuses a predicate that answers anything else.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__verdict() {
  __silt__VERDICT=''
  __silt__ask __silt__VERDICT "$@" || return $?

  case "$__silt__VERDICT" in
    true | false) ;;
    *)
      __silt__fail "a predicate answers true or false, not '$__silt__VERDICT'"
      return 1
      ;;
  esac
}
