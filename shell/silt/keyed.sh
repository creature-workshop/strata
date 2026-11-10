#!/bin/sh

: <<'MODULE'
The paths a verb orders a list's elements by. silt__sort_by, silt__group_by,
silt__min and silt__max read their paths here and hand the list to the awk
tier, which reads each element's values at those paths.
MODULE

: <<'FUN'
Hands a list to the awk program of a verb that orders its elements by the
values at paths, and leaves what the program printed in __silt__ANSWER.
Refuses a document that is not a list.

args:
  $1  The verb's name without its prefix, which is also its awk program's
  $2  The list
  $@  The paths into each element; the element itself when none is given
FUN
__silt__hand_keyed() {
  __silt__hand_keyed__verb="$1"
  __silt__hand_keyed__list="$2"
  shift 2

  __silt__require_list "$__silt__hand_keyed__list" "$__silt__hand_keyed__verb" || return 1
  __silt__key_paths "$@" || return 1

  __silt__ANSWER=''
  __silt__hand_off "$__silt__hand_keyed__list" "order elements keyed $__silt__hand_keyed__verb"
}

: <<'FUN'
Sets __silt__SEGMENTS to the segments of every path given, as the awk tier
reads them: one segment on each line, and a line that holds the record
separator alone between two paths. The path "." has no segment and leaves
no line. Given no path, sets it to the empty string, which the awk tier
reads as the path ".".

  __silt__key_paths .run.at .name   ->  "run"
                                         "at"
                                         <the record separator>
                                         "name"

args:
  $@  The paths
FUN
__silt__key_paths() {
  __silt__key_paths__all=''
  __silt__key_paths__count=0

  for __silt__key_paths__path do
    __silt__path_segments "$__silt__key_paths__path" || return 1

    if [ "$__silt__key_paths__count" -gt 0 ]; then
      __silt__key_paths__all="$__silt__key_paths__all$__silt__NL$__silt__RS$__silt__NL"
    fi
    __silt__key_paths__all="$__silt__key_paths__all$__silt__SEGMENTS"
    __silt__key_paths__count=$((__silt__key_paths__count + 1))
  done

  __silt__SEGMENTS="$__silt__key_paths__all"
}

: <<'FUN'
Sets __silt__SEGMENTS to the segments of one path, one on each line, and to
the empty string for the path ".".

  __silt__path_segments '.run["at"]'   ->  "run"
                                            "at"

args:
  $1  The path
FUN
__silt__path_segments() {
  __silt__PATH="$1"
  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__SEGMENTS=''
  else
    __silt__all_segments || return 1
  fi
}
