#!/bin/sh

: <<'MODULE'
silt__arr: a list from documents.
MODULE

: <<'PUB_FUN'
Answers a list holding each document given, indexed from 0 in the order they
come; with none, the empty list.

  silt__arr doc '0.:str="a"' '0.:int=2'   ->  doc='0.0:str="a"
                                                   0.1:int=2'

args:
  $1  The name of the variable to answer in
  $@  The documents
PUB_FUN
silt__arr() {
  __silt__out "$1" || return 1
  __silt__arr__out="$__silt__OUT"
  shift

  __silt__ANSWER=''
  __silt__INDEX=0
  __silt__append_items "$@" || return 1

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi

  __silt__OUT="$__silt__arr__out"
  __silt__answer
}

: <<'FUN'
Appends each document to the list being built as its next element, counting
__silt__INDEX up from where it stands.

args:
  $@  The documents
FUN
__silt__append_items() {
  for __silt__append_items__item do
    __silt__nest "$__silt__INDEX" "$__silt__append_items__item" 0 || return 1
    __silt__INDEX=$((__silt__INDEX + 1))
  done
}
