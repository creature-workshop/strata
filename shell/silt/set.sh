#!/bin/sh

: <<'MODULE'
silt__set: puts a document at a path.
MODULE

: <<'PUB_FUN'
Puts a value at a path. If a member is already there, it is replaced along
with everything under it. If not, the value is added at the end of its
parent, and any missing parents on the way are created: a map, or a list
when the next path segment is an index. An empty path answers the value
itself.

Refuses when the document is not a map or a list, when the path runs through
a scalar, or when the path names a list index that does not exist; push is
what grows a list.

  silt__set doc '0."a":int=1' .b '0.:int=2'      ->  doc='0."a":int=1
                                                          0."b":int=2'
  silt__set doc '0."a":int=1' .a.b '0.:int=2'    ->  refused: not a collection at "a"

registers:
  __silt__NEW           The value
  __silt__WANT          The depth the next segment should be at
  __silt__DONE          Whether the value has been placed
  __silt__AT            The depth of the member being replaced
  __silt__SKIPPING      Whether the old lines of that member are being dropped
  __silt__PARENT_KIND   What kind of collection the next segment is looked for in
  __silt__PARENT_EMPTY  Whether that collection has a member yet

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
  $4  The value, a document
PUB_FUN
silt__set() {
  __silt__out "$1" || return 1
  __silt__set__out="$__silt__OUT"
  __silt__NEW="$4"

  __silt__PATH="$3"
  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__ANSWER="$__silt__NEW"
  else
    __silt__place_in "$2" || return 1
  fi

  __silt__OUT="$__silt__set__out"
  __silt__answer
}

: <<'FUN'
Places the value in a collection at the path already begun: walks the
document once, and adds the value at the end when the walk did not place it.

args:
  $1  The document, a map or a list
FUN
__silt__place_in() {
  __silt__require_collection "$1" || return 1
  __silt__start_placing
  __silt__all_segments || return 1
  __silt__spill "$__silt__NEW"

  __silt__AWK='set'
  __silt__walk "$1" __silt__place_line || return 1
  __silt__unspill

  if [ "$__silt__DONE" = false ] && [ "$__silt__HANDED" = false ]; then
    __silt__place_new || return 1
  fi
}

: <<'FUN'
Refuses a document that is not a map or a list, and records its kind in
__silt__PARENT_KIND for the walk.

args:
  $1  The document
FUN
__silt__require_collection() {
  __silt__require_collection__kind=''
  silt__type __silt__require_collection__kind "$1" || return 1
  __silt__has_members "$__silt__require_collection__kind" members || return 1

  __silt__PARENT_KIND="$__silt__require_collection__kind"
}

: <<'FUN'
Sets the walk's registers to the root: the first segment is looked for at
depth 0, nothing is placed or being dropped yet, and the answer is empty.
FUN
__silt__start_placing() {
  __silt__WANT=0
  __silt__DONE=false
  __silt__SKIPPING=false
  __silt__PARENT_EMPTY=true
  __silt__ANSWER=''
}

: <<'FUN'
Handles one line of the walk. The empty root's own line is dropped. Lines of
the member being replaced are dropped. Until the value is placed, each line
is checked against the segment being looked for; after that, lines are
copied through.

args:
  $1  The line
FUN
__silt__place_line() {
  case "$1" in
    0.:*) return 0 ;;
  esac

  __silt__parse "$1" || return 1

  if [ "$__silt__SKIPPING" = true ]; then
    if [ "$__silt__DEPTH" -gt "$__silt__AT" ]; then
      return 0
    fi
    __silt__SKIPPING=false
  fi

  if [ "$__silt__DONE" = false ]; then
    __silt__place_match "$1"
    return
  fi

  __silt__emit "$1"
}

: <<'FUN'
Checks a parsed line against the segment being looked for at the current
depth. A line shallower than that depth means the parent has ended, so the
value goes in before it. A line that does not match is copied through. A
matching line is replaced when the path ends there, and descended into when
it does not.

args:
  $1  The line
FUN
__silt__place_match() {
  if [ "$__silt__DEPTH" -lt "$__silt__WANT" ]; then
    __silt__place_new || return 1
    __silt__emit "$1"
    return
  fi

  if [ "$__silt__DEPTH" -eq "$__silt__WANT" ]; then
    __silt__PARENT_EMPTY=false
  fi

  if [ "$__silt__DEPTH" -ne "$__silt__WANT" ] || [ "$__silt__KEY" != "$__silt__SEGMENT" ]; then
    __silt__emit "$1"
    return
  fi

  __silt__place_match__key="$__silt__KEY"
  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__place_replace "$__silt__place_match__key"
    return
  fi

  __silt__place_descend "$1" "$__silt__place_match__key"
}

: <<'FUN'
Puts the value in place of the matched member and marks the member's old
lines to be dropped.

args:
  $1  The key, as the line writes it
FUN
__silt__place_replace() {
  __silt__nest "$1" "$__silt__NEW" "$__silt__WANT" || return 1
  __silt__DONE=true
  __silt__SKIPPING=true
  __silt__AT="$__silt__WANT"
}

: <<'FUN'
Copies the matched line through and moves the walk one level down, to the
next segment. Refuses when the member is a scalar, because a path cannot go
through one.

args:
  $1  The line
  $2  The key, as the line writes it
FUN
__silt__place_descend() {
  if [ "$__silt__LEAF" = true ] || [ "$__silt__TYPE" = null ]; then
    __silt__fail "not a collection at $2"
    return 1
  fi

  __silt__emit "$1"
  __silt__WANT=$((__silt__WANT + 1))
  __silt__PARENT_KIND="$__silt__TYPE"
  __silt__PARENT_EMPTY=true
}

: <<'FUN'
Adds the value as a new member at the current depth, creating any missing
parents on the way: a map, or a list when the next segment is an index. A
new key has to fit its parent: a name under a map, an index under a list,
and an index only as element 0 of a list that has nothing in it yet.
FUN
__silt__place_new() {
  __silt__place_new__depth="$__silt__WANT"

  while :; do
    __silt__place_new__key="$__silt__SEGMENT"
    __silt__place_new_key_ok "$__silt__place_new__key" || return 1
    __silt__next_segment || return 1

    if [ "$__silt__PATH_DONE" = true ]; then
      __silt__nest "$__silt__place_new__key" "$__silt__NEW" "$__silt__place_new__depth" || return 1
      __silt__DONE=true
      return
    fi

    __silt__place_parent "$__silt__place_new__key" "$__silt__place_new__depth"
    __silt__place_new__depth=$((__silt__place_new__depth + 1))
  done
}

: <<'FUN'
Creates a missing parent on the way to the value: a list when the segment
after it, now in __silt__SEGMENT, is an index, a map otherwise.

args:
  $1  The parent's key, as the line writes it
  $2  The parent's depth
FUN
__silt__place_parent() {
  __silt__segment_is_index "$__silt__SEGMENT"

  if [ "$__silt__IS_INDEX" = true ]; then
    __silt__emit "$2.$1:list"
    __silt__PARENT_KIND=list
  else
    __silt__emit "$2.$1:map"
    __silt__PARENT_KIND=map
  fi
  __silt__PARENT_EMPTY=true
}

: <<'FUN'
Sets __silt__IS_INDEX to true when a segment is an index, bare digits, and
to false when it is a quoted name.

args:
  $1  The segment, as a line writes a key
FUN
__silt__segment_is_index() {
  case "$1" in
    "$__silt__QUOTE"*) __silt__IS_INDEX=false ;;
    *) __silt__IS_INDEX=true ;;
  esac
}

: <<'FUN'
Refuses a new key that does not fit its parent: a name under a list, an
index under a map, or an index other than 0 in a list with nothing in it
yet.

args:
  $1  The key about to be added
FUN
__silt__place_new_key_ok() {
  case "$__silt__PARENT_KIND$1" in
    map"$__silt__QUOTE"*) return 0 ;;
    map*)
      __silt__fail "a map takes a name, not the index $1"
      return 1
      ;;
    list"$__silt__QUOTE"*)
      __silt__fail "a list takes an index, not the name $1"
      return 1
      ;;
  esac

  if [ "$__silt__PARENT_EMPTY" = true ] && [ "$1" = 0 ]; then
    return 0
  fi

  __silt__fail "no element $1 to set; push appends to a list"
  return 1
}
