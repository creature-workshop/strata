#!/bin/sh

: <<'MODULE'
silt__canon and silt__equals: one order for a map's members, and equality
that looks past the order.
MODULE

: <<'PUB_FUN'
Answers the document with every map's members in canonical order, the
order RFC 8785 gives: by the keys' UTF-16 code units, which is what jq -S
and the canonical JSON libraries agree on. Lists keep their order and every
line keeps its text, so two maps that hold the same members come out the
same bytes. This runs in awk whatever the document's size, since the shell
cannot order two strings.

  silt__canon doc '0."b":int=1
  0."a":int=2'   ->  doc='0."a":int=2
  0."b":int=1'

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__canon() {
  __silt__out "$1" || return 1
  __silt__canon__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__hand_off "$2" canon || return 1

  __silt__OUT="$__silt__canon__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers true when two documents are the same value and false otherwise:
the same bytes are the same value at once, and two documents that differ
as bytes are put in canonical order before they are compared, so a map
built in one order equals the same map built in another.

  silt__equals same '0."a":int=1
  0."b":int=2' '0."b":int=2
  0."a":int=1'   ->  same=true

args:
  $1  The name of the variable to answer in
  $2  One document
  $3  The other
PUB_FUN
silt__equals() {
  __silt__out "$1" || return 1
  __silt__equals__out="$__silt__OUT"

  if [ "$2" = "$3" ]; then
    __silt__ANSWER=true
  else
    __silt__equals_canonical "$2" "$3" || return 1
  fi

  __silt__OUT="$__silt__equals__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to true when the two documents are the same once each
is in canonical order, and to false otherwise.

args:
  $1  One document
  $2  The other
FUN
__silt__equals_canonical() {
  __silt__equals_canonical__one=''
  __silt__equals_canonical__other=''
  silt__canon __silt__equals_canonical__one "$1" || return 1
  silt__canon __silt__equals_canonical__other "$2" || return 1

  if [ "$__silt__equals_canonical__one" = "$__silt__equals_canonical__other" ]; then
    __silt__ANSWER=true
  else
    __silt__ANSWER=false
  fi
}
