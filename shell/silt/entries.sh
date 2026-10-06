#!/bin/sh

: <<'MODULE'
silt__entries: a map as a list of its keys and values.
MODULE

: <<'PUB_FUN'
Answers a map as a list with one element per member, in the order the map
holds them. Each element is a map of two members: "key", the member's key
as a str, and "value", the member's value. The empty map answers the empty
list. Refuses a document that is not a map.

  silt__entries doc '0."a":int=1
  0."b":list
  1.0:int=2'   ->  doc='0.0:map
                        1."key":str="a"
                        1."value":int=1
                        0.1:map
                        1."key":str="b"
                        1."value":list
                        2.0:int=2'

args:
  $1  Name of the variable that receives the result
  $2  The map
PUB_FUN
silt__entries() {
  __silt__out "$1" || return 1
  __silt__entries__out="$__silt__OUT"

  __silt__KIND=''
  silt__type __silt__KIND "$2" || return 1
  if [ "$__silt__KIND" != map ]; then
    __silt__fail "entries takes a map, not a $__silt__KIND"
    return 1
  fi

  __silt__ANSWER=''
  __silt__INDEX=0
  __silt__AWK='entries'
  __silt__walk "$2" __silt__entries__line || return 1

  __silt__answer_list
  __silt__OUT="$__silt__entries__out"
  __silt__answer
}

: <<'FUN'
Handles one line of the walk: a member's own line opens an entry, a deeper
line is added one level down, under the entry's "value", and the empty
map's one line is passed over.

args:
  $1  The line
FUN
__silt__entries__line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__emit_entry "$1" ;;
    *) __silt__emit "$((${1%%.*} + 1)).${1#*.}" ;;
  esac
}

: <<'FUN'
Adds an entry for one member to the answer: a map under the next index,
holding the member's key as a str and the member's own line as its value.
Counts __silt__INDEX up.

args:
  $1  The member's depth-0 line
FUN
__silt__emit_entry() {
  __silt__parse "$1" || return 1

  __silt__node_text
  __silt__emit "0.$__silt__INDEX:map"
  __silt__emit "1.\"key\":str=$__silt__KEY"
  __silt__emit "1.\"value\":$__silt__NODE"
  __silt__INDEX=$((__silt__INDEX + 1))
}
