#!/bin/sh

: <<'MODULE'
silt__each: a callback per member, with its key and its value.
MODULE

: <<'PUB_FUN'
Calls <callback> once per member of a map or a list, with the member's key
as text (a map's unquoted, a list's index), the member's value as a document
of its own, and the extra arguments after them. Stops at the first callback
that returns non-zero, returning its status.

  count_reads() { silt__len n "$2"; total=$((total + n)); }
  total=0
  silt__each count_reads "$tests"

registers:
  __silt__CALLBACK    The callback
  __silt__EXTRAS      The tail of its argument list, reading the extras by name
  __silt__MEMBER_KEY  The key of the member being gathered
  __silt__MEMBER      The value of the member being gathered
  __silt__OPEN        Whether a member is being gathered

args:
  $1  The callback
  $2  The document
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
silt__each() {
  __silt__CALLBACK="$1"
  __silt__each__doc="$2"
  shift 2

  __silt__each__kind=''
  silt__type __silt__each__kind "$__silt__each__doc" || return 1
  __silt__has_members "$__silt__each__kind" members || return 1
  __silt__hold_extras "$@"

  __silt__MEMBER_KEY=''
  __silt__MEMBER=''
  __silt__OPEN=false
  __silt__walk "$__silt__each__doc" __silt__each_line || return $?

  __silt__deliver_member
}

: <<'FUN'
Holds the extra arguments by name and spells, in __silt__EXTRAS, the tail
of the callback's argument list that reads them back, so no value is ever
re-read as shell.

args:
  $@  The extra arguments
FUN
__silt__hold_extras() {
  __silt__EXTRAS=''
  __silt__hold_extras__count=0

  for __silt__hold_extras__extra do
    __silt__hold_extras__count=$((__silt__hold_extras__count + 1))
    eval "__silt__hold_extras__extra_$__silt__hold_extras__count=\$__silt__hold_extras__extra"
    __silt__EXTRAS="$__silt__EXTRAS \"\$__silt__hold_extras__extra_$__silt__hold_extras__count\""
  done
}

: <<'FUN'
Handles one line of the walk: a depth-0 line opens a member, a deeper one
belongs to the member open. Returns the callback's status when it stops
the walk.

args:
  $1  The line
FUN
__silt__each_line() {
  __silt__parse "$1" || return 1

  if [ "$__silt__DEPTH" -eq 0 ]; then
    __silt__open_member
  else
    __silt__extend_member "$1"
  fi
}

: <<'FUN'
Delivers the member open, if one is, then opens the parsed line as the next:
its key as text, its value as a keyless root. A keyless line is an empty
collection, which ends the walk with no member at all. Returns the
callback's status when it stops the walk.
FUN
__silt__open_member() {
  __silt__deliver_member || return $?

  case "$__silt__KEY" in
    '')
      __silt__STOP=true
      return 0
      ;;
    "$__silt__QUOTE"*) silt__unwrap __silt__MEMBER_KEY "$__silt__KEY" || return 1 ;;
    *) __silt__MEMBER_KEY="$__silt__KEY" ;;
  esac

  if [ "$__silt__LEAF" = true ]; then
    __silt__MEMBER="0.:$__silt__TYPE=$__silt__VALUE"
  else
    __silt__MEMBER="0.:$__silt__TYPE"
  fi

  __silt__OPEN=true
}

: <<'FUN'
Adds a deeper line to the member open, moved up so the member's own members
sit at depth 0; the first one replaces the placeholder root.

args:
  $1  The line
FUN
__silt__extend_member() {
  case "$__silt__MEMBER" in
    0.:map | 0.:list) __silt__MEMBER="$((__silt__DEPTH - 1)).${1#*.}" ;;
    *) __silt__MEMBER="$__silt__MEMBER$__silt__NL$((__silt__DEPTH - 1)).${1#*.}" ;;
  esac
}

: <<'FUN'
Calls the callback with the member open, if one is, its key and value and
the extra arguments held by name, and returns the callback's status.
FUN
__silt__deliver_member() {
  if [ "$__silt__OPEN" = false ]; then
    return 0
  fi

  __silt__OPEN=false
  eval "\"\$__silt__CALLBACK\" \"\$__silt__MEMBER_KEY\" \"\$__silt__MEMBER\"$__silt__EXTRAS"
}
