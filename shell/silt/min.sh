#!/bin/sh

: <<'MODULE'
silt__min and silt__max: the element of a list that orders first, and the
one that orders last.
MODULE

: <<'PUB_FUN'
Answers the element of a list that orders first, as a document of its own.
Elements are ordered as silt__sort_by orders them: by themselves when no
path is given, and by the values at the paths inside each otherwise. Of
several elements that tie, answers the first. Answers the empty string for
an empty list, which no document is. Refuses a document that is not a list,
and a map or a list where a scalar is compared.

A list of whole numbers given without a path is compared in the shell. Any
other call runs in awk.

  silt__min doc '0.0:int=3
  0.1:int=1'   ->  doc='0.:int=1'

  silt__min first "$shards" .run.started_at   ->  the shard that started first

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
silt__min() {
  __silt__out "$1" || return 1
  __silt__min__out="$__silt__OUT"
  shift

  __silt__extreme min "$@" || return 1

  __silt__OUT="$__silt__min__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers the element of a list that orders last, as a document of its own.
Elements are ordered as silt__sort_by orders them: by themselves when no
path is given, and by the values at the paths inside each otherwise. Of
several elements that tie, answers the last. Answers the empty string for
an empty list, which no document is. Refuses a document that is not a list,
and a map or a list where a scalar is compared.

A list of whole numbers given without a path is compared in the shell. Any
other call runs in awk.

  silt__max doc '0.0:int=3
  0.1:int=1'   ->  doc='0.:int=3'

  silt__max longest "$areas" .length   ->  the area whose length is greatest

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
silt__max() {
  __silt__out "$1" || return 1
  __silt__max__out="$__silt__OUT"
  shift

  __silt__extreme max "$@" || return 1

  __silt__OUT="$__silt__max__out"
  __silt__answer
}

: <<'FUN'
Leaves in __silt__ANSWER the element of a list that orders first or last. A
call with a path goes to awk. A call without one walks the list in the
shell, and goes to awk when the walk meets an element the shell cannot
compare.

registers:
  __silt__EXTREME  Which end is wanted, min or max
  __silt__WHOLE    Whether every element the walk met is a whole number

args:
  $1  Which end is wanted, min or max
  $2  The list
  $@  The paths into each element
FUN
__silt__extreme() {
  if [ "$#" -gt 2 ]; then
    __silt__hand_keyed "$@"
    return
  fi

  __silt__EXTREME="$1"
  __silt__require_list "$2" "$1" || return 1

  __silt__SEGMENTS=''
  __silt__WHOLE=true
  __silt__ANSWER=''
  __silt__AWK="order elements keyed $1"
  __silt__walk "$2" __silt__extreme__line || return 1
  __silt__extreme__answer "$2"
}

: <<'FUN'
Turns what the walk left into the answer. A walk that went to awk left the
answer itself. A walk that met an element the shell cannot compare hands
the list to awk now. Any other walk left the whole number wanted, which
becomes an int document, or nothing for the empty list.

args:
  $1  The list
FUN
__silt__extreme__answer() {
  if [ "$__silt__HANDED" = true ]; then
    return 0
  fi
  if [ "$__silt__WHOLE" = false ]; then
    __silt__ANSWER=''
    __silt__hand_off "$1" "order elements keyed $__silt__EXTREME"
    return
  fi
  if [ -n "$__silt__ANSWER" ]; then
    __silt__ANSWER="0.:int=$__silt__ANSWER"
  fi
}

: <<'FUN'
Handles one line of the walk: an element's own line is compared, and the
empty list's one line is passed over.

args:
  $1  The line
FUN
__silt__extreme__line() {
  case "$1" in
    0.:*) ;;
    *) __silt__extreme__element "$1" ;;
  esac
}

: <<'FUN'
Compares one element with the whole number kept in __silt__ANSWER, and
keeps the one wanted. An element that is not an int, or an int too long
for the shell's arithmetic, ends the walk, since the shell cannot compare
it.

args:
  $1  The element's depth-0 line
FUN
__silt__extreme__element() {
  __silt__parse "$1" || return 1

  if [ "$__silt__TYPE" != int ] || [ "${#__silt__VALUE}" -gt 18 ]; then
    __silt__WHOLE=false
    __silt__STOP=true
    return 0
  fi
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER="$__silt__VALUE"
    return 0
  fi

  case "$__silt__EXTREME" in
    min) __silt__keep_lesser "$__silt__VALUE" ;;
    max) __silt__keep_greater "$__silt__VALUE" ;;
  esac
}

: <<'FUN'
Keeps a whole number in __silt__ANSWER when it is less than the one kept.

args:
  $1  The whole number
FUN
__silt__keep_lesser() {
  if [ "$1" -lt "$__silt__ANSWER" ]; then
    __silt__ANSWER="$1"
  fi
}

: <<'FUN'
Keeps a whole number in __silt__ANSWER when it is not less than the one
kept, so the last of several that tie is the one kept.

args:
  $1  The whole number
FUN
__silt__keep_greater() {
  if [ "$1" -ge "$__silt__ANSWER" ]; then
    __silt__ANSWER="$1"
  fi
}
