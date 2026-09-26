#!/bin/sh

: <<'MODULE'
silt__obj: a map from key and document pairs.
MODULE

: <<'PUB_FUN'
Answers a map holding each pair's document under its key, in the order the
pairs come; with no pairs, the empty map. A key is text and is quoted the
way a line spells it. Members are appended, so a key given twice appears
twice; silt__set replaces.

  silt__obj doc runner '0.:str="bats"' count '0.:int=3'   ->  doc='0."runner":str="bats"
                                                                    0."count":int=3'

args:
  $1  The name of the variable to answer in
  $@  Key and document, pair by pair
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
    __silt__obj_member "$1" "$2" || return 1
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
nested under it at depth 0.

args:
  $1  The key, as text
  $2  The document
FUN
__silt__obj_member() {
  __silt__wrap_literal "$1"
  __silt__nest "$__silt__LITERAL" "$2" 0
}
