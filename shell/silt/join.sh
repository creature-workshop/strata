#!/bin/sh

: <<'MODULE'
silt__join: a list's scalars as one text.
MODULE

: <<'PUB_FUN'
Answers the text of a list's elements joined by <separator>, each element
read as silt__string reads it: a str unquoted, another scalar as its
spelling, a null as "null". Refuses a list holding a collection.

  silt__join text '0.0:str="a"
  0.1:str="b"' ', '   ->  text='a, b'

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The separator; nothing when omitted
PUB_FUN
silt__join() {
  __silt__out "$1" || return 1
  __silt__join__out="$__silt__OUT"
  __silt__join__separator="${3-}"

  __silt__join__kind=''
  silt__type __silt__join__kind "$2" || return 1
  if [ "$__silt__join__kind" != list ]; then
    __silt__fail "join of a $__silt__join__kind, not a list"
    return 1
  fi

  __silt__JOINED=''
  __silt__FIRST=true

  __silt__join__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__join__ifs"

  for __silt__join__line do
    case "$__silt__join__line" in
      0.:*) ;;
      0.*) __silt__join_element "$__silt__join__line" "$__silt__join__separator" || return 1 ;;
    esac
  done

  __silt__ANSWER="$__silt__JOINED"
  __silt__OUT="$__silt__join__out"
  __silt__answer
}

: <<'FUN'
Adds one element's text to __silt__JOINED, after the separator unless it is
the first; a collection has no text, so it is refused, and its deeper lines
are never reached.

args:
  $1  The element's line
  $2  The separator
FUN
__silt__join_element() {
  __silt__parse "$1" || return 1
  if [ "$__silt__LEAF" = false ] && [ "$__silt__TYPE" != null ]; then
    __silt__fail "join of a list holding a collection"
    return 1
  fi

  __silt__string_of_scalar "0.:${1#*:}" || return 1

  if [ "$__silt__FIRST" = true ]; then
    __silt__JOINED="$__silt__ANSWER"
    __silt__FIRST=false
  else
    __silt__JOINED="$__silt__JOINED$2$__silt__ANSWER"
  fi
}
