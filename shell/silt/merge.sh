#!/bin/sh

: <<'MODULE'
silt__merge: one map laid over another, one level deep.
MODULE

: <<'PUB_FUN'
Answers the first map with the second laid over it, one level deep: a key
both hold takes the second map's value, in the first map's place, and a key
only the second holds is added after the first's members, in the second's
order. A value that is itself a map is replaced whole, not merged. This
runs in awk whatever the maps' size, the second map reaching it through the
spill file.

  silt__merge doc '0."a":int=1
  0."b":int=2' '0."b":int=3
  0."c":int=4'   ->  doc='0."a":int=1
  0."b":int=3
  0."c":int=4'

args:
  $1  The name of the variable to answer in
  $2  The map
  $3  The map laid over it
PUB_FUN
silt__merge() {
  __silt__out "$1" || return 1
  __silt__merge__out="$__silt__OUT"

  __silt__require_map "$2" merge || return 1
  __silt__require_map "$3" merge || return 1
  __silt__against_spilled "$2" "$3" 'order elements merge' || return 1

  __silt__OUT="$__silt__merge__out"
  __silt__answer
}

: <<'FUN'
Refuses a document that is not a map, naming the verb that needed one.

args:
  $1  The document
  $2  The verb's name, for the message
FUN
__silt__require_map() {
  __silt__require_map__kind=''
  silt__type __silt__require_map__kind "$1" || return 1

  if [ "$__silt__require_map__kind" != map ]; then
    __silt__fail "$2 takes a map, not a $__silt__require_map__kind"
    return 1
  fi
}
