#!/bin/sh

: <<'MODULE'
silt__deepmerge: one map laid over another, at every depth.

The verb keeps a list of the maps that are still to be merged, and works
through it one map at a time. No function calls itself.
MODULE

: <<'PUB_FUN'
Answers the first map with the second laid over it, at every depth. For a
key that both hold: two maps are merged in the same way, and for any other
pair the second map's value is used. A key that only the second holds is
added after the first's members. With the default for lists, the answer is
what jq gives for `$a * $b`.

  defaults="$(cat <<'SILT'
  0."a":map
  1."x":int=1
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."a":map
  1."y":int=2
  SILT
  )"
  silt__deepmerge doc "$defaults" "$overrides"

  doc is:
    0."a":map
    1."x":int=1
    1."y":int=2

--lists says what happens to two lists under the same key:

  replace  the second list is used; this is the default
  concat   the second list's elements follow the first's
  union    as concat, and then every element that is the same value as an
           earlier one is dropped, as silt__unique does

registers:
  __silt__deepmerge__MERGED   The map as merged so far
  __silt__deepmerge__OVER     The second map
  __silt__deepmerge__PENDING  The paths of the maps still to be merged, one on each
                              line
  __silt__deepmerge__LISTS    What happens to two lists: replace, concat or union

args:
  $1       The name of the variable to answer in
  $2       The map
  $3       The map laid over it
  --lists  replace, concat or union
PUB_FUN
silt__deepmerge() {
  __silt__out "$1" || return 1
  __silt__deepmerge__out="$__silt__OUT"

  __silt__require_map "${2:-}" deepmerge || return 1
  __silt__require_map "${3:-}" deepmerge || return 1
  __silt__deepmerge__take_lists "${4:-}" "${5:-}" || return 1

  __silt__deepmerge__MERGED="$2"
  __silt__deepmerge__OVER="$3"
  __silt__deepmerge__PENDING='.'
  while [ -n "$__silt__deepmerge__PENDING" ]; do
    __silt__deepmerge__merge_next_map || return 1
  done

  __silt__ANSWER="$__silt__deepmerge__MERGED"
  __silt__answer_in "$__silt__deepmerge__out"
}

: <<'FUN'
Sets __silt__deepmerge__LISTS from the arguments after the two maps. Refuses a flag
that is not --lists, and a value that is not replace, concat or union.

args:
  $1  --lists, or nothing
  $2  replace, concat or union
FUN
__silt__deepmerge__take_lists() {
  __silt__deepmerge__LISTS=replace
  if [ -z "$1" ]; then
    return 0
  fi

  case "$1 $2" in
    '--lists replace' | '--lists concat' | '--lists union') __silt__deepmerge__LISTS="$2" ;;
    *)
      __silt__fail "deepmerge accepts --lists replace, concat or union, not '$1 $2'"
      return 1
      ;;
  esac
}

: <<'FUN'
Takes the first path off __silt__deepmerge__PENDING, and lays the members that the
second map holds there over the members that the merged map holds there.
FUN
__silt__deepmerge__merge_next_map() {
  __silt__deepmerge__merge_next_map__path="${__silt__deepmerge__PENDING%%"$__silt__NL"*}"
  case "$__silt__deepmerge__PENDING" in
    *"$__silt__NL"*) __silt__deepmerge__PENDING="${__silt__deepmerge__PENDING#*"$__silt__NL"}" ;;
    *) __silt__deepmerge__PENDING='' ;;
  esac

  __silt__deepmerge__merge_next_map__over=''
  silt__get __silt__deepmerge__merge_next_map__over "$__silt__deepmerge__OVER" "$__silt__deepmerge__merge_next_map__path" || return 1
  if [ "$__silt__deepmerge__merge_next_map__over" = 0.:map ]; then
    return 0
  fi

  silt__each "$__silt__deepmerge__merge_next_map__over" __silt__deepmerge__merge_member "$__silt__deepmerge__merge_next_map__path"
}

: <<'FUN'
Lays one member of the second map over the merged map. It is the callback
of silt__each.

args:
  $1  The key, as text
  $2  The value in the second map, a document
  $3  The path of the map that holds the member
FUN
__silt__deepmerge__merge_member() {
  __silt__wrap_literal "$1"
  __silt__deepmerge__merge_member__path="${3%.}.$__silt__LITERAL"
  __silt__deepmerge__merge_member__value="$2"

  __silt__deepmerge__merge_member__held=''
  silt__get __silt__deepmerge__merge_member__held "$__silt__deepmerge__MERGED" "$__silt__deepmerge__merge_member__path" || return 1
  __silt__deepmerge__kinds_of "$__silt__deepmerge__merge_member__held" "$__silt__deepmerge__merge_member__value" || return 1

  case "$__silt__deepmerge__KINDS" in
    'map map') __silt__deepmerge__PENDING="$__silt__deepmerge__PENDING${__silt__deepmerge__PENDING:+$__silt__NL}$__silt__deepmerge__merge_member__path" ;;
    'list list') __silt__deepmerge__merge_lists "$__silt__deepmerge__merge_member__path" "$__silt__deepmerge__merge_member__held" "$__silt__deepmerge__merge_member__value" ;;
    *) silt__set __silt__deepmerge__MERGED "$__silt__deepmerge__MERGED" "$__silt__deepmerge__merge_member__path" "$__silt__deepmerge__merge_member__value" ;;
  esac
}

: <<'FUN'
Sets __silt__deepmerge__KINDS to the kinds of two values with a space between them.
The kind of no value is "none".

  __silt__deepmerge__kinds_of '0.:map' '0.0:int=1'   ->  'map list'

args:
  $1  The value that the merged map holds, a document or nothing
  $2  The value that the second map holds, a document
FUN
__silt__deepmerge__kinds_of() {
  __silt__deepmerge__kinds_of__held=none
  if [ -n "$1" ]; then
    silt__type __silt__deepmerge__kinds_of__held "$1" || return 1
  fi

  __silt__deepmerge__kinds_of__over=''
  silt__type __silt__deepmerge__kinds_of__over "$2" || return 1
  __silt__deepmerge__KINDS="$__silt__deepmerge__kinds_of__held $__silt__deepmerge__kinds_of__over"
}

: <<'FUN'
Puts two lists together as __silt__deepmerge__LISTS says, and places the result in
the merged map.

args:
  $1  The path of the list
  $2  The list that the merged map holds
  $3  The list that the second map holds
FUN
__silt__deepmerge__merge_lists() {
  __silt__deepmerge__merge_lists__path="$1"
  __silt__deepmerge__merge_lists__list="$3"

  if [ "$__silt__deepmerge__LISTS" != replace ]; then
    silt__concat __silt__deepmerge__merge_lists__list "$2" "$3" || return 1
  fi
  if [ "$__silt__deepmerge__LISTS" = union ]; then
    silt__unique __silt__deepmerge__merge_lists__list "$__silt__deepmerge__merge_lists__list" || return 1
  fi

  silt__set __silt__deepmerge__MERGED "$__silt__deepmerge__MERGED" "$__silt__deepmerge__merge_lists__path" "$__silt__deepmerge__merge_lists__list"
}
