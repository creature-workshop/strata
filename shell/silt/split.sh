#!/bin/sh

: <<'MODULE'
silt__split: text cut on a separator, as a list of str.
MODULE

: <<'PUB_FUN'
Answers the list of the parts of <text> between each <separator>, each a
str, empty parts left out; with no separator, the lines of the text.

  silt__split doc 'a,b' ','   ->  doc='0.0:str="a"
                                       0.1:str="b"'

A separator of one character, a newline included, is cut in one expansion;
a longer one is cut part by part.

args:
  $1  The name of the variable to answer in
  $2  The text; nothing when omitted
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

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi

  __silt__OUT="$__silt__split__out"
  __silt__answer
}

: <<'FUN'
Cuts the text on a one-character separator with the field split, and
appends each non-empty part as a str element.

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
Appends one part as the next str element, unless it is empty.

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
