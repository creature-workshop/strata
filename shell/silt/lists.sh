#!/bin/sh

: <<'FRAGMENT'
What a merge does with two lists under the same key: the --lists option of
silt__merge and silt__deepmerge.
FRAGMENT

: <<'FUN'
Sets __silt__lists__POLICY from the two arguments that follow a merge's
maps: replace when there are none, and otherwise the value given after
--lists. Refuses a flag that is not --lists, and a value that is not
replace, concat or union.

  __silt__lists__take merge '' ''             ->  __silt__lists__POLICY=replace
  __silt__lists__take merge --lists replace   ->  __silt__lists__POLICY=replace
  __silt__lists__take merge --lists concat    ->  __silt__lists__POLICY=concat
  __silt__lists__take merge --lists union     ->  __silt__lists__POLICY=union

args:
  $1  The verb's name, for the message
  $2  --lists, or nothing
  $3  replace, concat or union
FUN
__silt__lists__take() {
  __silt__lists__POLICY=replace
  if [ -z "$2" ]; then
    return 0
  fi

  case "$2 $3" in
    '--lists replace' | '--lists concat' | '--lists union') __silt__lists__POLICY="$3" ;;
    *)
      __silt__fail "$1 accepts --lists replace, concat or union, not '$2 $3'"
      return 1
      ;;
  esac
}

: <<'FUN'
Sets __silt__lists__JOINED to two lists put together as a policy says: the
second list for replace, the second list's elements after the first's for
concat, and for union the same with every element dropped that is the same
value as an earlier one, as silt__unique does.

  __silt__lists__join concat '0.0:int=1' '0.0:int=2'
    ->  __silt__lists__JOINED='0.0:int=1
  0.1:int=2'

args:
  $1  replace, concat or union
  $2  The first list
  $3  The second list
FUN
__silt__lists__join() {
  __silt__lists__JOINED="$3"
  if [ "$1" = replace ]; then
    return 0
  fi

  silt__concat __silt__lists__JOINED "$2" "$3" || return 1
  if [ "$1" = union ]; then
    silt__unique __silt__lists__JOINED "$__silt__lists__JOINED"
  fi
}
