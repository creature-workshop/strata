#!/bin/sh

: <<'FRAGMENT'
Helpers for a call that takes several paths. One helper finds the first
path that has a value. The other puts each value of a list of path and
value pairs at its path.
FRAGMENT

: <<'FUN'
Reads a list of paths, with --default and its value anywhere among them,
and finds the first path that holds a value that is not a null.

  __silt__paths__choose "$doc" .a .b --default x
    ->  __silt__paths__CHOSEN is the value at .a, or else the value at .b

registers:
  __silt__paths__CHOSEN       The value at the first path that holds one.
                              When no path does, what the last path holds:
                              a null, or the empty string.
  __silt__paths__IS_CHOSEN    Whether a path held a value that is not a null
  __silt__paths__DEFAULT      The value after --default
  __silt__paths__HAS_DEFAULT  Whether the call has --default

args:
  $1  The document
  $@  The paths, and --default with its value
FUN
__silt__paths__choose() {
  __silt__paths__choose__doc="$1"
  shift

  __silt__paths__CHOSEN=''
  __silt__paths__IS_CHOSEN=false
  __silt__paths__DEFAULT=''
  __silt__paths__HAS_DEFAULT=false

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --default) __silt__paths__keep_default "$@" || return 1 ;;
      *) __silt__paths__try_path "$__silt__paths__choose__doc" "$1" || return 1 ;;
    esac
    shift "$__silt__paths__TAKEN"
  done
}

: <<'FUN'
Keeps the value after --default, and sets __silt__paths__TAKEN to 2, the number of
arguments read. Refuses --default with no value after it.

args:
  $1  --default
  $2  The value
FUN
__silt__paths__keep_default() {
  if [ "$#" -lt 2 ]; then
    __silt__fail '--default requires a value'
    return 1
  fi

  __silt__paths__DEFAULT="$2"
  __silt__paths__HAS_DEFAULT=true
  __silt__paths__TAKEN=2
}

: <<'FUN'
Reads the value at one path, unless an earlier path already held a value,
and sets __silt__paths__TAKEN to 1, the number of arguments read.

args:
  $1  The document
  $2  The path
FUN
__silt__paths__try_path() {
  __silt__paths__TAKEN=1
  if [ "$__silt__paths__IS_CHOSEN" = true ]; then
    return 0
  fi

  silt__get __silt__paths__CHOSEN "$1" "$2" || return 1
  silt__defined __silt__paths__IS_CHOSEN "$__silt__paths__CHOSEN"
}

: <<'FUN'
Puts each value at its path in a document, one pair after another, and
assigns the result to the caller's variable. A later pair sees what an
earlier pair placed. Refuses a path that has no value after it.

args:
  $1  true to leave out a pair whose value is the empty string
  $2  The name of the variable to answer in
  $3  The document
  $@  A path and a value, pair by pair
FUN
__silt__paths__set_pairs() {
  __silt__out "${2:-}" || return 1
  __silt__paths__set_pairs__skip="$1"
  __silt__paths__set_pairs__out="$__silt__OUT"
  __silt__paths__PAIRED="${3:-}"
  shift 3

  if [ "$(($# % 2))" -ne 0 ]; then
    __silt__fail 'a path has no value after it; give a path and a value in pairs'
    return 1
  fi

  while [ "$#" -gt 0 ]; do
    __silt__paths__set_pair "$__silt__paths__set_pairs__skip" "$1" "$2" || return 1
    shift 2
  done

  __silt__ANSWER="$__silt__paths__PAIRED"
  __silt__answer_in "$__silt__paths__set_pairs__out"
}

: <<'FUN'
Puts one value at its path in __silt__paths__PAIRED, the document that
__silt__paths__set_pairs is building.

args:
  $1  true to leave out a value that is the empty string
  $2  The path
  $3  The value, a document
FUN
__silt__paths__set_pair() {
  if [ "$1" = true ] && [ -z "$3" ]; then
    return 0
  fi

  silt__set __silt__paths__PAIRED "$__silt__paths__PAIRED" "$2" "$3"
}
