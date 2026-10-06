#!/bin/sh

: <<'MODULE'
silt__obj: builds a map from key and document pairs.
MODULE

: <<'PUB_FUN'
Builds a map from key and document pairs, in the order given. With no pairs
it builds the empty map. A key is plain text; the map quotes it. Members are
appended as given, so a key given twice appears twice; silt__set is what
replaces a member.

  silt__obj doc runner '0.:str="bats"' count '0.:int=3'   ->  doc='0."runner":str="bats"
                                                                    0."count":int=3'

args:
  $1  The name of the variable to answer in
  $@  A key and a document, pair by pair
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
