#!/bin/sh

: <<'MODULE'
silt__push: appends documents to a list.
MODULE

: <<'PUB_FUN'
Appends documents to the end of a list, numbering them on from its last
index.

  silt__push doc '0.0:str="a"' '0.:int=2'   ->  doc='0.0:str="a"
                                                     0.1:int=2'

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The documents to append
PUB_FUN
silt__push() {
  __silt__out "$1" || return 1
  __silt__push__out="$__silt__OUT"
  __silt__push__list="$2"
  shift 2

  __silt__require_list "$__silt__push__list" push || return 1
  __silt__continue_list "$__silt__push__list"
  __silt__append_items "$@" || return 1

  __silt__answer_list
  __silt__OUT="$__silt__push__out"
  __silt__answer
}
