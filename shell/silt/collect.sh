#!/bin/sh

: <<'MODULE'
silt__collect: a run of documents as a list.
MODULE

: <<'PUB_FUN'
Answers the list of the documents in <run>, where a line holding the record
separator alone (__silt__RS) stands between one document and the next; a
run with no separator is one document, and an empty run is the empty list.

  silt__collect doc "0.:int=1
  $__silt__RS
  0.:int=2"   ->  doc='0.0:int=1
                       0.1:int=2'

args:
  $1  The name of the variable to answer in
  $2  The run; nothing when omitted
PUB_FUN
silt__collect() {
  __silt__out "$1" || return 1
  __silt__collect__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__INDEX=0
  __silt__PENDING=''

  __silt__collect__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- ${2-}
  set +f
  IFS="$__silt__collect__ifs"

  for __silt__collect__line do
    if [ "$__silt__collect__line" = "$__silt__RS" ]; then
      __silt__collect_pending || return 1
    else
      __silt__PENDING="$__silt__PENDING${__silt__PENDING:+$__silt__NL}$__silt__collect__line"
    fi
  done
  __silt__collect_pending || return 1

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi

  __silt__OUT="$__silt__collect__out"
  __silt__answer
}

: <<'FUN'
Appends the document gathered so far in __silt__PENDING as the next element,
if there is one, and empties it.
FUN
__silt__collect_pending() {
  if [ -z "$__silt__PENDING" ]; then
    return 0
  fi

  __silt__nest "$__silt__INDEX" "$__silt__PENDING" 0 || return 1
  __silt__INDEX=$((__silt__INDEX + 1))
  __silt__PENDING=''
}
