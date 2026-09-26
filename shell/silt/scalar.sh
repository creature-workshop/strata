#!/bin/sh

: <<'MODULE'
silt__scalar: the value text of a scalar document.
MODULE

: <<'PUB_FUN'
Answers the value text of a scalar document: the JSON literal of a str, the
digits of an int, "true" or "false", and the empty string for a null or an
empty collection.

  silt__scalar text '0.:str="bats"'   ->  text='"bats"'
  silt__scalar text '0.:int=3'        ->  text=3

args:
  $1  The name of the variable to answer in
  $2  The document, one keyless line
PUB_FUN
silt__scalar() {
  __silt__out "$1" || return 1
  __silt__one_line "$2" || return 1
  __silt__parse "$2" || return 1

  if [ -n "$__silt__KEY" ]; then
    __silt__fail "not a scalar document, its line: $2"
    return 1
  fi

  __silt__ANSWER="$__silt__VALUE"
  __silt__answer
}

: <<'FUN'
Refuses a document of more than one line, naming its first.

args:
  $1  The document
FUN
__silt__one_line() {
  __silt__one_line__first="${1%%"$__silt__NL"*}"

  if [ "$__silt__one_line__first" != "$1" ]; then
    __silt__fail "not a scalar document, its first line: $__silt__one_line__first"
    return 1
  fi
}
