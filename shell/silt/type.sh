#!/bin/sh

: <<'MODULE'
silt__type: the kind of value a document is.
MODULE

: <<'PUB_FUN'
Answers what kind of value a document is: map or list from the key of its
first member, else the type of its one keyless line.

  silt__type kind '0."a":int=1'   ->  kind=map
  silt__type kind '0.0:int=1'     ->  kind=list
  silt__type kind '0.:str="x"'    ->  kind=str

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__type() {
  __silt__out "$1" || return 1
  __silt__parse "${2%%"$__silt__NL"*}" || return 1
  case "$__silt__KEY" in
    '') __silt__ANSWER="$__silt__TYPE" ;;
    '"'*) __silt__ANSWER=map ;;
    *) __silt__ANSWER=list ;;
  esac
  __silt__answer
}
