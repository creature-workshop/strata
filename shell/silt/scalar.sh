#!/bin/sh

: <<'MODULE'
silt__scalar: the value text of a scalar document.
MODULE

: <<'PUB_FUN'
The plumbing of @scalar: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_scalar.sh documents it.
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
