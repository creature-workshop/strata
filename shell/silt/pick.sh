#!/bin/sh

: <<'FRAGMENT'
silt__pick and silt__without: a map with only some of its keys, or without
some of them.
FRAGMENT

: <<'PUB_FUN'
Answers the map with only the members under the keys given, in the map's
own order. A key that the map does not hold is left out. Refuses a document
that is not a map.

  silt__pick doc '0."title":str="t"
  0."token":str="s"
  0."body":str="b"' title body   ->  doc='0."title":str="t"
                                         0."body":str="b"'

args:
  $1  The name of the variable to answer in
  $2  The map
  $@  The keys to keep
PUB_FUN
silt__pick() {
  __silt__require_map "${2:-}" pick || return 1
  __silt__pick__out="$1"
  __silt__pick__map="$2"
  shift 2

  silt__filter "$__silt__pick__out" "$__silt__pick__map" __silt__pick__key_is_among true "$@"
}

: <<'PUB_FUN'
Answers the map without the members under the keys given. Use it to take a
secret out of a map before the map is logged. Refuses a document that is
not a map.

  silt__without doc '0."title":str="t"
  0."token":str="s"' token   ->  doc='0."title":str="t"'

args:
  $1  The name of the variable to answer in
  $2  The map
  $@  The keys to leave out
PUB_FUN
silt__without() {
  __silt__require_map "${2:-}" without || return 1
  __silt__without__out="$1"
  __silt__without__map="$2"
  shift 2

  silt__filter "$__silt__without__out" "$__silt__without__map" __silt__pick__key_is_among false "$@"
}

: <<'FUN'
Answers one word when a member's key is one of the keys given, and the
opposite word when it is not. It is a predicate for silt__filter.

  __silt__pick__key_is_among out title "$value" true title body   ->  out=true
  __silt__pick__key_is_among out token "$value" true title body   ->  out=false

args:
  $1  The name of the variable to answer in
  $2  The member's key, as text
  $3  The member's value, unread here
  $4  The word to answer when the key is one of the keys: true or false
  $@  The keys
FUN
__silt__pick__key_is_among() {
  __silt__pick__key_is_among__out="$1"
  __silt__pick__key_is_among__key="$2"
  __silt__pick__key_is_among__found="$4"
  shift 4

  silt__not __silt__pick__key_is_among__missing "0.:bool=$__silt__pick__key_is_among__found" || return 1
  __silt__ANSWER="${__silt__pick__key_is_among__missing#0.:bool=}"

  for __silt__pick__key_is_among__one in "$@"; do
    if [ "$__silt__pick__key_is_among__one" = "$__silt__pick__key_is_among__key" ]; then
      __silt__ANSWER="$__silt__pick__key_is_among__found"
    fi
  done

  __silt__answer_in "$__silt__pick__key_is_among__out"
}
