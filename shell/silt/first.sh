#!/bin/sh

: <<'MODULE'
silt__first and silt__last: the element at either end of a list.
MODULE

: <<'PUB_FUN'
Answers the first element of a list as a document of its own. Answers the
empty string for an empty list, which no document is. Refuses a document
that is not a list.

  silt__first doc '0.0:str="a"
  0.1:str="b"'   ->  doc='0.:str="a"'

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
silt__first() {
  __silt__require_list "$2" first || return 1
  silt__get "$1" "$2" '.[0]'
}

: <<'PUB_FUN'
Answers the last element of a list as a document of its own. Answers the
empty string for an empty list, which no document is. Refuses a document
that is not a list.

  silt__last doc '0.0:str="a"
  0.1:str="b"'   ->  doc='0.:str="b"'

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
silt__last() {
  __silt__require_list "$2" last || return 1

  __silt__last__count=0
  silt__len __silt__last__count "$2" || return 1
  if [ "$__silt__last__count" -eq 0 ]; then
    __silt__last__count=1
  fi

  silt__get "$1" "$2" ".[$((__silt__last__count - 1))]"
}
