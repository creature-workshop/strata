#!/bin/sh

: <<'MODULE'
silt__concat: two lists, one after the other.
MODULE

: <<'PUB_FUN'
Answers the first list with the second's elements after it, re-indexed to
continue the first's count.

  silt__concat doc '0.0:str="a"' '0.0:str="b"'   ->  doc='0.0:str="a"
                                                          0.1:str="b"'

args:
  $1  The name of the variable to answer in
  $2  The first list
  $3  The second list
PUB_FUN
silt__concat() {
  __silt__out "$1" || return 1
  __silt__concat__out="$__silt__OUT"

  __silt__both_lists "$2" "$3" || return 1

  __silt__count_members "$2"
  __silt__INDEX="$__silt__ANSWER"
  __silt__ANSWER="$2"
  if [ "$__silt__INDEX" -eq 0 ]; then
    __silt__ANSWER=''
  fi

  __silt__append_list "$3" || return 1

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi

  __silt__OUT="$__silt__concat__out"
  __silt__answer
}

: <<'FUN'
Refuses either document when it is not a list.

args:
  $1  The first document
  $2  The second document
FUN
__silt__both_lists() {
  __silt__both_lists__kind=''

  silt__type __silt__both_lists__kind "$1" || return 1
  if [ "$__silt__both_lists__kind" != list ]; then
    __silt__fail "concat of a $__silt__both_lists__kind, not a list"
    return 1
  fi

  silt__type __silt__both_lists__kind "$2" || return 1
  if [ "$__silt__both_lists__kind" != list ]; then
    __silt__fail "concat with a $__silt__both_lists__kind, not a list"
    return 1
  fi
}

: <<'FUN'
Appends a list's lines to the answer, each element's index moved on by
__silt__INDEX and its deeper lines kept as they are; the empty list adds
nothing.

args:
  $1  The list
FUN
__silt__append_list() {
  __silt__append_list__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $1
  set +f
  IFS="$__silt__append_list__ifs"

  for __silt__append_list__line do
    case "$__silt__append_list__line" in
      0.:*) ;;
      0.*) __silt__append_element "$__silt__append_list__line" ;;
      *) __silt__emit "$__silt__append_list__line" ;;
    esac
  done
}

: <<'FUN'
Appends one element's own line with its index moved on by __silt__INDEX.

args:
  $1  The element's depth-0 line
FUN
__silt__append_element() {
  __silt__append_element__rest="${1#0.}"
  __silt__append_element__index="${__silt__append_element__rest%%:*}"
  __silt__emit "0.$((__silt__append_element__index + __silt__INDEX)):${__silt__append_element__rest#*:}"
}
