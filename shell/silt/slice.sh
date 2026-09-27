#!/bin/sh

: <<'MODULE'
silt__slice: part of a list, from one index up to another.
MODULE

: <<'PUB_FUN'
Answers the elements of a list from the index <from> up to, but not
including, the index <to>, as a list numbered from 0. An index past the end
of the list takes what there is, so the answer may be shorter than asked,
or the empty list. Refuses a document that is not a list, and an index that
is not a whole number of 0 or more.

  silt__slice doc '0.0:str="a"
  0.1:str="b"
  0.2:str="c"' 1 3   ->  doc='0.0:str="b"
                              0.1:str="c"'

registers:
  __silt__FROM     The index of the first element to keep
  __silt__TO       The index after the last element to keep
  __silt__KEEPING  Whether the element being read is one to keep

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  The index of the first element to keep
  $4  The index after the last element to keep
PUB_FUN
silt__slice() {
  __silt__out "$1" || return 1
  __silt__slice__out="$__silt__OUT"

  __silt__require_list "$2" slice || return 1
  __silt__require_index "$3" slice || return 1
  __silt__require_index "$4" slice || return 1

  __silt__FROM="$3"
  __silt__TO="$4"
  __silt__KEEPING=false
  __silt__ANSWER=''
  __silt__AWK='slice'
  __silt__walk "$2" __silt__slice_line || return 1

  __silt__answer_list
  __silt__OUT="$__silt__slice__out"
  __silt__answer
}

: <<'FUN'
Refuses an index that is not a whole number of 0 or more, in the name of
the verb that asked.

args:
  $1  The index
  $2  The verb
FUN
__silt__require_index() {
  case "$1" in
    '' | *[!0-9]*)
      __silt__fail "$2 takes an index of 0 or more, not '$1'"
      return 1
      ;;
  esac
}

: <<'FUN'
Handles one line of the walk. An element's own line decides whether the
element is kept. A deeper line belongs to the element before it, and is
kept when that element is.

args:
  $1  The line
FUN
__silt__slice_line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__slice_element "$1" ;;
    *) __silt__emit_kept "$1" ;;
  esac
}

: <<'FUN'
Reads an element's own line. Keeps the element, numbered from 0, when its
index is within the range, and ends the walk once the range is passed.

args:
  $1  The element's depth-0 line
FUN
__silt__slice_element() {
  __silt__slice_element__rest="${1#0.}"
  __silt__slice_element__index="${__silt__slice_element__rest%%:*}"

  __silt__KEEPING=false
  if [ "$__silt__slice_element__index" -ge "$__silt__TO" ]; then
    __silt__STOP=true
    return 0
  fi
  if [ "$__silt__slice_element__index" -ge "$__silt__FROM" ]; then
    __silt__KEEPING=true
    __silt__emit "0.$((__silt__slice_element__index - __silt__FROM)):${__silt__slice_element__rest#*:}"
  fi
}

: <<'FUN'
Adds a line to the answer when the element it belongs to is being kept.

args:
  $1  The line
FUN
__silt__emit_kept() {
  if [ "$__silt__KEEPING" = true ]; then
    __silt__emit "$1"
  fi
}
