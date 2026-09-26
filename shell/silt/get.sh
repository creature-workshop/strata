#!/bin/sh

: <<'MODULE'
silt__get: the value at a path, as a document of its own.
MODULE

: <<'PUB_FUN'
Answers the value at a path as a document of its own: a leaf becomes one
keyless line, a collection becomes its members at depth 0, an empty
collection or a null its one keyless line. Answers the empty string for a
path nothing holds, which no document is.

  silt__get runner "$doc" '.suites.unit.runner'   ->  runner='0.:str="bats"'
  silt__get reads "$doc" '.suites.unit.tests'     ->  reads='0."test/a.bats":map
                                                              1."reads":list
                                                              2.0:str="lib/a.sh"'

The walk keeps four registers: __silt__WANT, the depth the next segment sits
at; __silt__FOUND, whether the value's line was reached, and __silt__AT, its
depth; __silt__DONE, whether the rest of the document can be skipped.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__get() {
  __silt__out "$1" || return 1
  __silt__get__out="$__silt__OUT"

  __silt__PATH="$3"
  __silt__next_segment || return 1

  if [ "$__silt__PATH_DONE" = true ]; then
    __silt__ANSWER="$2"
    __silt__OUT="$__silt__get__out"
    __silt__answer
    return
  fi

  __silt__WANT=0
  __silt__FOUND=false
  __silt__DONE=false
  __silt__ANSWER=''

  __silt__get__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__get__ifs"

  for __silt__get__line do
    __silt__parse "$__silt__get__line" || return 1
    __silt__walk_line "$__silt__get__line" || return 1

    if [ "$__silt__DONE" = true ]; then
      break
    fi
  done

  if [ "$__silt__FOUND" = false ]; then
    __silt__ANSWER=''
  fi

  __silt__OUT="$__silt__get__out"
  __silt__answer
}

: <<'FUN'
Takes one parsed line of the walk: while the value is still being looked
for, matches the line against the segment wanted; once found, collects the
line as a member.

args:
  $1  The line, as parsed into the registers
FUN
__silt__walk_line() {
  if [ "$__silt__FOUND" = true ]; then
    __silt__collect_member "$1"
  else
    __silt__match_segment
  fi
}

: <<'FUN'
Matches the parsed line against the segment wanted at the depth wanted. A
line shallower than that ends the walk unfound; a line that is not the
segment is skipped; the segment itself either ends the path, and is the
value, or sends the walk one level down after the next segment.
FUN
__silt__match_segment() {
  if [ "$__silt__DEPTH" -lt "$__silt__WANT" ]; then
    __silt__DONE=true
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
Collects a line after the value was found: a line no deeper than the value
ends the walk; a deeper one is a member, re-depthed so the value's own
members sit at 0, and the first member replaces the placeholder root.

args:
  $1  The line, as parsed into the registers
FUN
__silt__collect_member() {
  if [ "$__silt__DEPTH" -le "$__silt__AT" ]; then
    __silt__DONE=true
    return
  fi

  case "$__silt__ANSWER" in
    0.:map | 0.:list) __silt__ANSWER='' ;;
  esac

  __silt__emit "$((__silt__DEPTH - __silt__AT - 1)).${1#*.}"
}
