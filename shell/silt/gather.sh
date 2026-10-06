#!/bin/sh

: <<'MODULE'
Building a collection member by member, for the verbs over each: it starts
as the one keyless line that says its kind, and each member added replaces
that line or follows the last.
MODULE

: <<'FUN'
Starts the collection in __silt__COLLECTED as the empty one of the
document's kind, map or list, with no member kept yet. Refuses a document
that is neither.

args:
  $1  The document whose members the verb walks
FUN
__silt__start_collecting() {
  __silt__start_collecting__kind=''
  silt__type __silt__start_collecting__kind "$1" || return 1
  __silt__has_members "$__silt__start_collecting__kind" members || return 1

  __silt__COLLECTED="0.:$__silt__start_collecting__kind"
  __silt__KEPT=0
}

: <<'FUN'
Appends a member to the collection in __silt__COLLECTED, under its key when
the collection is a map and as the next element when it is a list, and
counts __silt__KEPT up.

args:
  $1  The key, as text; unread under a list
  $2  The member's value, a document
FUN
__silt__keep_member() {
  __silt__ANSWER="$__silt__COLLECTED"
  __silt__gather__member "$1" "$__silt__KEPT" "$2" || return 1
  __silt__COLLECTED="$__silt__ANSWER"
  __silt__KEPT=$((__silt__KEPT + 1))
}

: <<'FUN'
Appends a member to the collection in __silt__ANSWER at depth 0: under the
key, quoted, when the collection is a map, and under the index when it is a
list. The empty collection's keyless line gives way to the first member.

  __silt__gather__member reads 0 '0.:int=1'   ->  0."reads":int=1 under a map
                                                  0.0:int=1        under a list

args:
  $1  The key, as text
  $2  The index, bare digits
  $3  The member's value, a document
FUN
__silt__gather__member() {
  case "$__silt__ANSWER" in
    0.:map | 0."$__silt__QUOTE"*) __silt__gather__named "$1" "$3" ;;
    *) __silt__gather__indexed "$2" "$3" ;;
  esac
}

: <<'FUN'
Appends a member to the map in __silt__ANSWER under its key, quoted.

args:
  $1  The key, as text
  $2  The member's value, a document
FUN
__silt__gather__named() {
  __silt__wrap_literal "$1"
  __silt__drop_placeholder
  __silt__nest "$__silt__LITERAL" "$2" 0
}

: <<'FUN'
Appends a member to the list in __silt__ANSWER under its index.

args:
  $1  The index, bare digits
  $2  The member's value, a document
FUN
__silt__gather__indexed() {
  __silt__drop_placeholder
  __silt__nest "$1" "$2" 0
}

: <<'FUN'
Empties __silt__ANSWER when it is the empty collection's one keyless line,
so the first member takes its place.
FUN
__silt__drop_placeholder() {
  case "$__silt__ANSWER" in
    0.:map | 0.:list) __silt__ANSWER='' ;;
  esac
}
