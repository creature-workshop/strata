#!/bin/sh

: <<'MODULE'
silt__pluck: the value at a path in each member, as a list.
MODULE

: <<'PUB_FUN'
Answers a list holding, for each member in order, the value at the path
inside it, as a document of its own; null where a member holds nothing at
the path.

  silt__pluck names '0.0:map
  1."name":str="build"
  0.1:map
  1."name":str="test"' .name   ->  names='0.0:str="build"
                                          0.1:str="test"'

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The path into each member
PUB_FUN
silt__pluck() {
  __silt__out "$1" || return 1
  __silt__pluck__out="$__silt__OUT"

  __silt__COLLECTED='0.:list'
  __silt__KEPT=0
  silt__each "$2" __silt__pluck_member "$3" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__OUT="$__silt__pluck__out"
  __silt__answer
}

: <<'FUN'
Handles one member: appends the value at the path inside it to the list, or
null when it holds none.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The path
FUN
__silt__pluck_member() {
  __silt__PLUCKED=''
  silt__get __silt__PLUCKED "$2" "$3" || return 1

  __silt__keep_member '' "${__silt__PLUCKED:-0.:null}"
}
