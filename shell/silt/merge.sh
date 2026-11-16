#!/bin/sh

: <<'MODULE'
silt__merge: one map laid over another, one level deep.
MODULE

: <<'PUB_FUN'
Answers the first map with the second laid over it, one level deep: a key
both hold takes the second map's value, in the first map's place, and a key
only the second holds is added after the first's members, in the second's
order. A value that is itself a map is replaced whole, not merged.

  defaults="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."b":int=3
  0."c":int=4
  SILT
  )"
  silt__merge doc "$defaults" "$overrides"

  doc is:
    0."a":int=1
    0."b":int=3
    0."c":int=4

--lists says what happens to two lists under the same key:

  replace  the second list is used; this is the default
  concat   the second list's elements follow the first's
  union    as concat, and then every element that is the same value as an
           earlier one is dropped, as silt__unique does

  defaults="$(cat <<'SILT'
  0."l":list
  1.0:int=1
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."l":list
  1.0:int=2
  SILT
  )"
  silt__merge doc "$defaults" "$overrides" --lists concat

  doc is:
    0."l":list
    1.0:int=1
    1.1:int=2

With replace, this runs in awk whatever the maps' size.

args:
  $1       The name of the variable to answer in
  $2       The map
  $3       The map laid over it
  --lists  replace, concat or union
PUB_FUN
silt__merge() {
  __silt__out "$1" || return 1
  __silt__merge__out="$__silt__OUT"

  __silt__require_map "$2" merge || return 1
  __silt__require_map "$3" merge || return 1
  __silt__lists__take merge "${4:-}" "${5:-}" || return 1

  __silt__merge__lay "$2" "$3" "$__silt__lists__POLICY" || return 1
  __silt__answer__in "$__silt__merge__out"
}

: <<'FUN'
Sets __silt__ANSWER to the first map with the second laid over it, one
level deep, with two lists under the same key put together as the policy
says.

args:
  $1  The map
  $2  The map laid over it
  $3  replace, concat or union
FUN
__silt__merge__lay() {
  if [ "$3" = replace ]; then
    __silt__hand_off_with "$1" "$2" 'order elements merge'
  else
    __silt__merge__lay_joining_lists "$1" "$2" "$3"
  fi
}

: <<'FUN'
Sets __silt__ANSWER to the first map with each member of the second laid
over it in turn, two lists under the same key put together as the policy
says.

registers:
  __silt__merge__MERGED  The map as merged so far

args:
  $1  The map
  $2  The map laid over it
  $3  concat or union
FUN
__silt__merge__lay_joining_lists() {
  __silt__merge__MERGED="$1"
  silt__each "$2" __silt__merge__lay_member "$3" || return 1
  __silt__ANSWER="$__silt__merge__MERGED"
}

: <<'FUN'
Lays one member of the second map over the merged map. It is the callback
of silt__each.

args:
  $1  The key, as text
  $2  The value in the second map, a document
  $3  concat or union
FUN
__silt__merge__lay_member() {
  __silt__wrap_literal "$1"
  __silt__merge__lay_member__path=".$__silt__LITERAL"
  __silt__merge__lay_member__value="$2"

  __silt__merge__lay_member__held=''
  silt__get __silt__merge__lay_member__held "$__silt__merge__MERGED" "$__silt__merge__lay_member__path" || return 1
  __silt__merge__are_lists "$__silt__merge__lay_member__held" "$2" || return 1
  if [ "$__silt__merge__ARE_LISTS" = true ]; then
    __silt__lists__join "$3" "$__silt__merge__lay_member__held" "$2" || return 1
    __silt__merge__lay_member__value="$__silt__lists__JOINED"
  fi

  silt__set __silt__merge__MERGED "$__silt__merge__MERGED" "$__silt__merge__lay_member__path" "$__silt__merge__lay_member__value"
}

: <<'FUN'
Sets __silt__merge__ARE_LISTS to true when both values are lists, and to
false otherwise.

args:
  $1  The value that the merged map holds, a document or nothing
  $2  The value that the second map holds, a document
FUN
__silt__merge__are_lists() {
  __silt__merge__ARE_LISTS=false
  if [ -z "$1" ]; then
    return 0
  fi

  __silt__merge__are_lists__held=''
  silt__type __silt__merge__are_lists__held "$1" || return 1
  __silt__merge__are_lists__over=''
  silt__type __silt__merge__are_lists__over "$2" || return 1
  if [ "$__silt__merge__are_lists__held $__silt__merge__are_lists__over" = 'list list' ]; then
    __silt__merge__ARE_LISTS=true
  fi
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
