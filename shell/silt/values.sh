#!/bin/sh

: <<'MODULE'
silt__values: a map's values, as a list.
MODULE

: <<'PUB_FUN'
The plumbing of @values: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_values.sh documents it.
PUB_FUN
silt__values() {
  __silt__out "$1" || return 1
  __silt__values__out="$__silt__OUT"

  __silt__KIND=''
  silt__type __silt__KIND "$2" || return 1
  __silt__has_members "$__silt__KIND" values || return 1

  __silt__ANSWER=''
  __silt__INDEX=0
  __silt__AWK='values'
  __silt__walk "$2" __silt__values__line || return 1

  __silt__answer_list
  __silt__OUT="$__silt__values__out"
  __silt__answer
}

: <<'FUN'
Handles one line of the walk: a member's own line is added under the next
index, a deeper line is added as it is, and the empty collection's one line
is passed over.

args:
  $1  The line
FUN
__silt__values__line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__emit_value "$1" ;;
    *) __silt__emit "$1" ;;
  esac
}

: <<'FUN'
Adds a member's own line to the answer with an index in place of its key,
counting __silt__INDEX up.

args:
  $1  The member's depth-0 line
FUN
__silt__emit_value() {
  __silt__parse "$1" || return 1

  __silt__node_text
  __silt__emit "0.$__silt__INDEX:$__silt__NODE"
  __silt__INDEX=$((__silt__INDEX + 1))
}

: <<'FUN'
Sets __silt__NODE to what the line last parsed writes after its key: its
type, and for a leaf an equals sign and its value.

  0."a":str="x"  ->  str="x"
  0."a":map      ->  map
FUN
__silt__node_text() {
  if [ "$__silt__LEAF" = true ]; then
    __silt__NODE="$__silt__TYPE=$__silt__VALUE"
  else
    __silt__NODE="$__silt__TYPE"
  fi
}
