#!/bin/sh

: <<'MODULE'
silt__project: the members named of each member, as a list of maps.
MODULE

: <<'PUB_FUN'
Answers a list holding, for each member in order, a map of the keys named
and the values the member holds under them, in the order the keys are
given; null under a key the member lacks.

  silt__project shown "$records" name status   ->  shown='0.0:map
                                                          1."name":str="build"
                                                          1."status":str="passed"
                                                          0.1:map
                                                          ...'

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $@  The keys, at least one
PUB_FUN
silt__project() {
  __silt__out "$1" || return 1
  __silt__project__out="$__silt__OUT"
  __silt__project__doc="$2"
  shift 2

  if [ "$#" -eq 0 ]; then
    __silt__fail "project takes at least one key"
    return 1
  fi

  __silt__COLLECTED='0.:list'
  __silt__KEPT=0
  silt__each "$__silt__project__doc" __silt__project__member "$@" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__OUT="$__silt__project__out"
  __silt__answer
}

: <<'FUN'
Handles one member: builds in __silt__PROJECTED the map of the keys named
and what the member holds under them, and appends it to the list.

args:
  $1  The key, as text
  $2  The value, a document
  $@  The keys to project
FUN
__silt__project__member() {
  __silt__project__member__value="$2"
  shift 2

  __silt__PROJECTED='0.:map'
  for __silt__project__member__key do
    __silt__project__field "$__silt__project__member__value" "$__silt__project__member__key" || return 1
  done

  __silt__keep_member '' "$__silt__PROJECTED"
}

: <<'FUN'
Appends one key to the map in __silt__PROJECTED, with the value the member
holds under it, or null when it holds none.

args:
  $1  The member's value, a document
  $2  The key, as text
FUN
__silt__project__field() {
  __silt__wrap_literal "$2"
  __silt__PLUCKED=''
  silt__get __silt__PLUCKED "$1" ".$__silt__LITERAL" || return 1

  __silt__ANSWER="$__silt__PROJECTED"
  __silt__gather__member "$2" '' "${__silt__PLUCKED:-0.:null}" || return 1
  __silt__PROJECTED="$__silt__ANSWER"
}
