#!/bin/sh

: <<'MODULE'
silt__obj: builds a map from key and document pairs.
MODULE

: <<'PUB_FUN'
The plumbing of @obj: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_obj.sh documents it.
PUB_FUN
silt__obj() {
  __silt__out "$1" || return 1
  __silt__obj__out="$__silt__OUT"
  shift

  __silt__ANSWER=''
  if [ "$#" -eq 0 ]; then
    __silt__ANSWER='0.:map'
  fi

  while [ "$#" -ge 2 ]; do
    __silt__obj__member "$1" "$2" || return 1
    shift 2
  done

  if [ "$#" -eq 1 ]; then
    __silt__fail "a key without a document: $1"
    return 1
  fi

  __silt__OUT="$__silt__obj__out"
  __silt__answer
}

: <<'FUN'
Appends one member to the map being built: the key quoted, the document
under it at depth 0.

args:
  $1  The key, as text
  $2  The document
FUN
__silt__obj__member() {
  __silt__wrap_literal "$1"
  __silt__nest "$__silt__LITERAL" "$2" 0
}
