#!/bin/sh

: <<'MODULE'
silt__push: appends documents to a list.
MODULE

: <<'PUB_FUN'
Appends documents to the end of a list, numbering them on from its last
index. Given --at and a path, appends them to the list at that path inside
the document, and answers the whole document.

  silt__push doc '0.0:str="a"' '0.:int=2'   ->  doc='0.0:str="a"
                                                     0.1:int=2'

  suite="$(cat <<'SILT'
  0."tests":list
  1.0:str="a"
  SILT
  )"
  silt__push doc "$suite" --at .tests '0.:int=2'

  doc is:
    0."tests":list
    1.0:str="a"
    1.1:int=2

args:
  $1    The name of the variable to answer in
  $2    The list, or with --at the document that holds it
  --at  The path of the list inside the document
  $@    The documents to append
PUB_FUN
silt__push() {
  if [ "${3:-}" = --at ]; then
    __silt__push__at "$@"
    return
  fi

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

: <<'FUN'
Appends documents to the list at a path inside a document, and answers the
whole document. Refuses --at with no path after it, and a path that does
not hold a list.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  --at
  $4  The path of the list
  $@  The documents to append
FUN
__silt__push__at() {
  __silt__out "$1" || return 1
  __silt__push__at__out="$__silt__OUT"
  __silt__push__at__doc="$2"
  __silt__push__at__path="${4:-}"
  shift "$(($# < 4 ? $# : 4))"

  if [ -z "$__silt__push__at__path" ]; then
    __silt__fail '--at requires a path'
    return 1
  fi

  __silt__push__at__list=''
  silt__get __silt__push__at__list "$__silt__push__at__doc" "$__silt__push__at__path" || return 1
  if [ -z "$__silt__push__at__list" ]; then
    __silt__fail "push found no list at '$__silt__push__at__path'"
    return 1
  fi

  silt__push __silt__push__at__list "$__silt__push__at__list" "$@" || return 1
  silt__set "$__silt__push__at__out" "$__silt__push__at__doc" "$__silt__push__at__path" "$__silt__push__at__list"
}
