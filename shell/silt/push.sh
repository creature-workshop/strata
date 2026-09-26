#!/bin/sh

: <<'MODULE'
silt__push: documents appended to a list.
MODULE

: <<'PUB_FUN'
Answers the list with each document given appended after its last element,
indexed on from where the list ends.

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

  __silt__push__kind=''
  silt__type __silt__push__kind "$__silt__push__list" || return 1
  if [ "$__silt__push__kind" != list ]; then
    __silt__fail "push onto a $__silt__push__kind, not a list"
    return 1
  fi

  __silt__count_members "$__silt__push__list"
  __silt__INDEX="$__silt__ANSWER"
  __silt__ANSWER="$__silt__push__list"
  if [ "$__silt__INDEX" -eq 0 ]; then
    __silt__ANSWER=''
  fi

  __silt__append_items "$@" || return 1

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi

  __silt__OUT="$__silt__push__out"
  __silt__answer
}
