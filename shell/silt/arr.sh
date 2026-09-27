#!/bin/sh

: <<'MODULE'
silt__arr: builds a list from documents.
MODULE

: <<'PUB_FUN'
Builds a list from the documents given, in order, indexed from 0. With no
documents it builds the empty list.

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

  __silt__answer_list
  __silt__OUT="$__silt__arr__out"
  __silt__answer
}

: <<'FUN'
Appends each document to the list being built as its next element, and
counts __silt__INDEX up as it goes.

args:
  $@  The documents
FUN
__silt__append_items() {
  for __silt__append_items__item do
    __silt__nest "$__silt__INDEX" "$__silt__append_items__item" 0 || return 1
    __silt__INDEX=$((__silt__INDEX + 1))
  done
}

: <<'FUN'
Makes the list built so far the answer: the lines appended, or the empty
list's one line when nothing was.
FUN
__silt__answer_list() {
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi
}

: <<'FUN'
Starts building on an existing list: the answer is its lines, or nothing
when it is empty, and __silt__INDEX is the index its next element takes.

args:
  $1  The list
FUN
__silt__continue_list() {
  __silt__count_members "$1"
  __silt__INDEX="$__silt__ANSWER"

  if [ "$__silt__INDEX" -eq 0 ]; then
    __silt__ANSWER=''
  else
    __silt__ANSWER="$1"
  fi
}

: <<'FUN'
Refuses a document that is not a list, naming the verb that needed one.

args:
  $1  The document
  $2  The verb's name, for the message
FUN
__silt__require_list() {
  __silt__require_list__kind=''
  silt__type __silt__require_list__kind "$1" || return 1

  if [ "$__silt__require_list__kind" != list ]; then
    __silt__fail "$2 takes a list, not a $__silt__require_list__kind"
    return 1
  fi
}
