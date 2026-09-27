#!/bin/sh

: <<'MODULE'
silt__split: makes a list of str from text.
MODULE

: <<'PUB_FUN'
Cuts text on a separator and builds a list of str from the parts. Empty
parts are dropped. Without a separator the text is cut on newlines.

  silt__split doc 'a,b' ','   ->  doc='0.0:str="a"
                                       0.1:str="b"'

A one-character separator, a newline included, is cut in one field split. A
longer separator is cut part by part from the front.

args:
  $1  The name of the variable to answer in
  $2  The text; empty when omitted
  $3  The separator; a newline when omitted or empty
PUB_FUN
silt__split() {
  __silt__out "$1" || return 1
  __silt__split__out="$__silt__OUT"
  __silt__split__separator="${3:-$__silt__NL}"

  __silt__ANSWER=''
  __silt__INDEX=0

  if [ "${#__silt__split__separator}" -eq 1 ]; then
    __silt__split_on_character "${2-}" "$__silt__split__separator" || return 1
  else
    __silt__split_on_text "${2-}" "$__silt__split__separator" || return 1
  fi

  __silt__answer_list
  __silt__OUT="$__silt__split__out"
  __silt__answer
}

: <<'FUN'
Cuts the text on a one-character separator with a field split, and appends
each non-empty part as a str element.

args:
  $1  The text
  $2  The separator, one character
FUN
__silt__split_on_character() {
  __silt__split_on_character__ifs="$IFS"
  IFS="$2"
  set -f
  # shellcheck disable=SC2086
  set -- $1
  set +f
  IFS="$__silt__split_on_character__ifs"

  for __silt__split_on_character__part do
    __silt__append_part "$__silt__split_on_character__part" || return 1
  done
}

: <<'FUN'
Cuts the text on a separator of several characters, one part at a time from
the front, and appends each non-empty part as a str element.

args:
  $1  The text
  $2  The separator
FUN
__silt__split_on_text() {
  __silt__split_on_text__rest="$1"

  while :; do
    case "$__silt__split_on_text__rest" in
      *"$2"*) ;;
      *) break ;;
    esac
    __silt__append_part "${__silt__split_on_text__rest%%"$2"*}" || return 1
    __silt__split_on_text__rest="${__silt__split_on_text__rest#*"$2"}"
  done

  __silt__append_part "$__silt__split_on_text__rest" || return 1
}

: <<'FUN'
Appends one part as the next str element. An empty part is skipped.

args:
  $1  The part
FUN
__silt__append_part() {
  if [ -z "$1" ]; then
    return 0
  fi

  __silt__wrap_literal "$1"
  __silt__emit "0.$__silt__INDEX:str=$__silt__LITERAL"
  __silt__INDEX=$((__silt__INDEX + 1))
}
