#!/bin/sh

: <<'MODULE'
silt__set: a document placed at a path, in place of what was there.
MODULE

: <<'PUB_FUN'
Answers the document with <value> at <path>: the member there is replaced,
subtree and all, and a member that was not there is added at the end of its
parent, with any missing parents on the way created as maps, or as lists
where the next segment is an index. The empty path answers <value> itself.
Refuses a document that is not a map or a list, a path that runs through a
scalar, and an index that is not there, since push is what grows a list.

  silt__set doc '0."a":int=1' .b '0.:int=2'      ->  doc='0."a":int=1
                                                          0."b":int=2'
  silt__set doc '0."a":int=1' .a.b '0.:int=2'    ->  refused: not a collection at "a"

The walk keeps __silt__WANT, the depth the next segment sits at; __silt__DONE,
whether the value is placed; __silt__AT with __silt__SKIPPING, the depth of
the member being replaced while its old lines are dropped; and
__silt__PARENT_KIND with __silt__PARENT_EMPTY, what the collection the next
segment is looked for in is, and whether it has a member yet.

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
    __silt__OUT="$__silt__set__out"
    __silt__answer
    return
  fi

  __silt__set__kind=''
  silt__type __silt__set__kind "$2" || return 1
  __silt__has_members "$__silt__set__kind" members || return 1

  __silt__WANT=0
  __silt__DONE=false
  __silt__SKIPPING=false
  __silt__PARENT_KIND="$__silt__set__kind"
  __silt__PARENT_EMPTY=true
  __silt__ANSWER=''

  __silt__set__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__set__ifs"

  for __silt__set__line do
    __silt__place_line "$__silt__set__line" || return 1
  done

  if [ "$__silt__DONE" = false ]; then
    __silt__place_new || return 1
  fi

  __silt__OUT="$__silt__set__out"
  __silt__answer
}

: <<'FUN'
Takes one line of the walk: the empty root's own line is dropped, a line of
the member being replaced is dropped, and until the value is placed a line
is matched against the segment wanted; after that it is kept as it is.

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
Matches the parsed line against the segment wanted at the depth wanted. A
line shallower than that closes the parent, so the value goes in before it;
a line that is not the segment is kept; the segment itself is replaced when
it ends the path, or descended into when it does not.

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
Places the value under the matched key, in place of the member there, and
marks the member's old lines for dropping.

args:
  $1  The key, as the line spells it
FUN
__silt__place_replace() {
  __silt__nest "$1" "$__silt__NEW" "$__silt__WANT" || return 1
  __silt__DONE=true
  __silt__SKIPPING=true
  __silt__AT="$__silt__WANT"
}

: <<'FUN'
Keeps the matched line and sends the walk one level down after the next
segment; refuses when the member is a scalar, since a path cannot run
through one.

args:
  $1  The line
  $2  The key, as the line spells it
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
Places the value as a new member at the depth wanted, under the segment
wanted, creating each further segment on the way as a map, or as a list
when the segment after it is an index. A key must suit its parent: a name
under a map, an index under a list, and an index only as element 0 of a
list with no element yet, since push is what grows a list.
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

    case "$__silt__SEGMENT" in
      [0-9]*)
        __silt__emit "$__silt__place_new__depth.$__silt__place_new__key:list"
        __silt__PARENT_KIND=list
        ;;
      *)
        __silt__emit "$__silt__place_new__depth.$__silt__place_new__key:map"
        __silt__PARENT_KIND=map
        ;;
    esac
    __silt__PARENT_EMPTY=true
    __silt__place_new__depth=$((__silt__place_new__depth + 1))
  done
}

: <<'FUN'
Refuses a new key that does not suit the parent in __silt__PARENT_KIND: a
name under a list, an index under a map, or an index other than element 0
of a list with no element yet.

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
