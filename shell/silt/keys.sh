#!/bin/sh

: <<'MODULE'
silt__keys: the members' keys, as a list document.
MODULE

: <<'PUB_FUN'
Answers the members' keys as a list document: a map's as str leaves holding
the key literals in the order they sit, a list's as int leaves.

  silt__keys names '0."b":int=1
  0."a":int=2'   ->  names='0.0:str="b"
  0.1:str="a"'

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__keys() {
  __silt__out "$1" || return 1
  __silt__keys__out="$__silt__OUT"

  __silt__KIND=''
  silt__type __silt__KIND "$2" || return 1
  __silt__has_members "$__silt__KIND" keys || return 1

  __silt__ANSWER=''
  __silt__INDEX=0
  __silt__AWK='keys'
  __silt__walk "$2" __silt__keys_line || return 1
  __silt__absorb_handed

  __silt__answer_list
  __silt__OUT="$__silt__keys__out"
  __silt__answer
}

: <<'FUN'
Handles one line of the walk: a member's own line adds its key, a deeper
line is passed over, and the empty collection's one line ends the walk.

args:
  $1  The line
FUN
__silt__keys_line() {
  case "$1" in
    0.:*) __silt__STOP=true ;;
    0.*) __silt__emit_key "$1" ;;
  esac
}

: <<'FUN'
Refuses a document that is not a map or a list, in the name of the verb that
asked, since nothing else has members.

args:
  $1  The kind silt__type answered
  $2  What the verb wanted of the members: keys, or members
FUN
__silt__has_members() {
  case "$1" in
    map | list) ;;
    *)
      __silt__fail "$1 has no $2"
      return 1
      ;;
  esac
}

: <<'FUN'
Appends one member's key to the answer as its next element, counting
__silt__INDEX up: a str leaf holding a map's key literal, an int leaf holding
a list's index, by the kind in __silt__KIND.

args:
  $1  The member's line
FUN
__silt__emit_key() {
  __silt__parse "$1" || return 1

  case "$__silt__KIND" in
    map) __silt__emit "0.$__silt__INDEX:str=$__silt__KEY" ;;
    *) __silt__emit "0.$__silt__INDEX:int=$__silt__KEY" ;;
  esac

  __silt__INDEX=$((__silt__INDEX + 1))
}
