#!/bin/sh

: <<'MODULE'
silt__type: the kind of value a document is.
MODULE

: <<'PUB_FUN'
Answers what kind of value a document is: map or list from the key of its
first member, else the type of its one keyless line. Given a path, answers
the kind of the value at that path, and the empty string when the path
holds nothing.

  silt__type kind '0."a":int=1'      ->  kind=map
  silt__type kind '0.0:int=1'        ->  kind=list
  silt__type kind '0.:str="x"'       ->  kind=str
  silt__type kind '0."a":int=1' .a   ->  kind=int
  silt__type kind '0."a":int=1' .b   ->  kind=

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path, when given
PUB_FUN
silt__type() {
  if [ "$#" -ge 3 ]; then
    __silt__type__at "$@"
    return
  fi

  __silt__out "$1" || return 1
  __silt__parse "${2%%"$__silt__NL"*}" || return 1

  case "$__silt__KEY" in
    '') __silt__ANSWER="$__silt__TYPE" ;;
    "$__silt__QUOTE"*) __silt__ANSWER=map ;;
    *) __silt__ANSWER=list ;;
  esac

  __silt__answer
}

: <<'FUN'
Answers the kind of the value at a path, and the empty string when the path
holds nothing.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
FUN
__silt__type__at() {
  __silt__out "$1" || return 1
  __silt__type__at__out="$__silt__OUT"

  __silt__type__at__value=''
  silt__get __silt__type__at__value "$2" "$3" || return 1
  if [ -z "$__silt__type__at__value" ]; then
    __silt__ANSWER=''
    __silt__answer__in "$__silt__type__at__out"
    return
  fi

  silt__type "$__silt__type__at__out" "$__silt__type__at__value"
}
