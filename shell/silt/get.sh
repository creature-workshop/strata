#!/bin/sh

: <<'MODULE'
silt__get: the value at a path, as a document of its own.
MODULE

: <<'PUB_FUN'
Answers the value at a path as a document of its own: a leaf becomes one
keyless line, a collection becomes its members at depth 0, an empty
collection or a null its one keyless line. Answers the empty string for a
path nothing holds, which no document is.

Given several paths, answers the value at the first path that holds a value
that is not a null. When no path does, answers the document after
--default, or without --default what the last path holds.

  silt__get nodes "$doc" .nodes .edges --default '0.:list'

  silt__get runner "$doc" '.suites.unit.runner'   ->  runner='0.:str="bats"'
  silt__get reads "$doc" '.suites.unit.tests'     ->  reads='0."test/a.bats":map
                                                              1."reads":list
                                                              2.0:str="lib/a.sh"'

registers:
  __silt__WANT   The depth the next segment should be at
  __silt__FOUND  Whether the value's own line has been reached
  __silt__AT     The depth of the value's own line

args:
  $1  The name of the variable to answer in
  $2  The document
  $@  The path, or several paths
  --default  The document to answer when no path holds a value
PUB_FUN
silt__get() {
  if [ "$#" -ne 3 ]; then
    __silt__get_first "$@"
    return
  fi

  __silt__out "$1" || return 1
  __silt__get__out="$__silt__OUT"

  __silt__PATH="$3"
  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__ANSWER="$2"
  else
    __silt__find_in "$2" || return 1
  fi

  __silt__OUT="$__silt__get__out"
  __silt__answer
}

: <<'FUN'
Walks the document for the path already begun, and leaves the value in
__silt__ANSWER, or nothing when no member is there.

args:
  $1  The document
FUN
__silt__find_in() {
  __silt__WANT=0
  __silt__FOUND=false
  __silt__ANSWER=''
  __silt__all_segments || return 1

  __silt__AWK='get'
  __silt__walk "$1" __silt__find_line || return 1

  if [ "$__silt__FOUND" = false ] && [ "$__silt__HANDED" = false ]; then
    __silt__ANSWER=''
  fi
}

: <<'FUN'
Handles one line of the walk: until the value is found, the line is matched
against the segment being looked for; after that, it is collected as a
member of the value.

args:
  $1  The line
FUN
__silt__find_line() {
  __silt__parse "$1" || return 1

  if [ "$__silt__FOUND" = true ]; then
    __silt__collect_member "$1"
  else
    __silt__match_segment
  fi
}

: <<'FUN'
Matches the parsed line against the segment being looked for at the current
depth. A line shallower than that depth ends the walk without a value. A
line that is not the segment is skipped. The segment itself is the value
when the path ends there, and otherwise sends the walk one level down after
the next segment.
FUN
__silt__match_segment() {
  if [ "$__silt__DEPTH" -lt "$__silt__WANT" ]; then
    __silt__STOP=true
    return
  fi

  if [ "$__silt__DEPTH" -ne "$__silt__WANT" ] || [ "$__silt__KEY" != "$__silt__SEGMENT" ]; then
    return
  fi

  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__found_value
  else
    __silt__WANT=$((__silt__WANT + 1))
  fi
}

: <<'FUN'
Marks the parsed line as the value and starts the answer with it as a
keyless root: a leaf keeps its value; a collection or a null is its type
alone until a member replaces it.
FUN
__silt__found_value() {
  __silt__FOUND=true
  __silt__AT="$__silt__DEPTH"

  if [ "$__silt__LEAF" = true ]; then
    __silt__ANSWER="0.:$__silt__TYPE=$__silt__VALUE"
  else
    __silt__ANSWER="0.:$__silt__TYPE"
  fi
}

: <<'FUN'
Collects a line after the value was found. A line no deeper than the value
ends the walk. A deeper one is a member, moved up so the value's own
members sit at depth 0, and the first member replaces the placeholder root.

args:
  $1  The line
FUN
__silt__collect_member() {
  if [ "$__silt__DEPTH" -le "$__silt__AT" ]; then
    __silt__STOP=true
    return
  fi

  case "$__silt__ANSWER" in
    0.:map | 0.:list) __silt__ANSWER='' ;;
  esac

  __silt__emit "$((__silt__DEPTH - __silt__AT - 1)).${1#*.}"
}

: <<'FUN'
Answers the value at the first of several paths that holds a value that is
not a null, or else the default, or else what the last path holds.

args:
  $1  The name of the variable to answer in
  $2  The document
  $@  The paths, and --default with a document
FUN
__silt__get_first() {
  __silt__out "${1:-}" || return 1
  __silt__get_first__out="$__silt__OUT"
  __silt__get_first__doc="${2:-}"
  shift 2

  __silt__paths__choose "$__silt__get_first__doc" "$@" || return 1

  __silt__ANSWER="$__silt__paths__CHOSEN"
  if [ "$__silt__paths__IS_CHOSEN" = false ] && [ "$__silt__paths__HAS_DEFAULT" = true ]; then
    __silt__ANSWER="$__silt__paths__DEFAULT"
  fi
  __silt__answer_in "$__silt__get_first__out"
}
