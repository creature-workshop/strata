#!/bin/sh

: <<'MODULE'
silt__pop, silt__shift, silt__take and silt__take_last: a list with
elements taken from either end.
MODULE

: <<'PUB_FUN'
Answers the last element of a list and, when the caller names a second
variable, the list without that element. For an empty list the element is
the empty string, which no document is, and the rest is the empty list.
Refuses a document that is not a list.

  silt__pop last rest '0.0:str="a"
  0.1:str="b"'   ->  last='0.:str="b"'  rest='0.0:str="a"'

  silt__pop last '0.0:str="a"
  0.1:str="b"'   ->  last='0.:str="b"'

args:
  $1  Name of the variable that receives the last element
  $2  Name of the variable that receives the rest of the list, when given
  $3  The list
PUB_FUN
silt__pop() {
  if [ "$#" -lt 3 ]; then
    __silt__require_list "${2:-}" pop || return 1
    silt__last "$@"
    return
  fi
  __silt__require_list "$3" pop || return 1

  __silt__pop__count=0
  silt__len __silt__pop__count "$3" || return 1
  if [ "$__silt__pop__count" -eq 0 ]; then
    __silt__pop__count=1
  fi

  silt__last "$1" "$3" || return 1
  silt__slice "$2" "$3" 0 "$((__silt__pop__count - 1))"
}

: <<'PUB_FUN'
Answers the first element of a list and, when the caller names a second
variable, the list without that element, numbered from 0. For an empty
list the element is the empty string, which no document is, and the rest
is the empty list. Refuses a document that is not a list.

  silt__shift first rest '0.0:str="a"
  0.1:str="b"'   ->  first='0.:str="a"'  rest='0.0:str="b"'

  silt__shift first '0.0:str="a"
  0.1:str="b"'   ->  first='0.:str="a"'

args:
  $1  Name of the variable that receives the first element
  $2  Name of the variable that receives the rest of the list, when given
  $3  The list
PUB_FUN
silt__shift() {
  if [ "$#" -lt 3 ]; then
    __silt__require_list "${2:-}" shift || return 1
    silt__first "$@"
    return
  fi
  __silt__require_list "$3" shift || return 1

  __silt__shift__count=0
  silt__len __silt__shift__count "$3" || return 1

  silt__first "$1" "$3" || return 1
  silt__slice "$2" "$3" 1 "$((__silt__shift__count + 1))"
}

: <<'PUB_FUN'
Answers the first <count> elements of a list. When the list has fewer, it
answers the whole list and logs a warning. Refuses a document that is not a
list, and a count that is not a whole number of 0 or more.

  silt__take doc '0.0:str="a"
  0.1:str="b"' 1   ->  doc='0.0:str="a"'

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  How many elements to take
PUB_FUN
silt__take() {
  __silt__require_list "${2:-}" take || return 1
  __silt__require_index "${3:-}" take || return 1

  __silt__take__count=0
  silt__len __silt__take__count "$2" || return 1
  if [ "$3" -gt "$__silt__take__count" ]; then
    warn "silt: take asked for $3 elements and the list has $__silt__take__count"
  fi

  silt__slice "$1" "$2" 0 "$3"
}

: <<'PUB_FUN'
Answers the last <count> elements of a list, numbered from 0. When the list
has fewer, it answers the whole list and logs a warning. Refuses a document
that is not a list, and a count that is not a whole number of 0 or more.

  silt__take_last doc '0.0:str="a"
  0.1:str="b"' 1   ->  doc='0.0:str="b"'

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  How many elements to take
PUB_FUN
silt__take_last() {
  __silt__require_list "${2:-}" take_last || return 1
  __silt__require_index "${3:-}" take_last || return 1

  __silt__take_last__count=0
  silt__len __silt__take_last__count "$2" || return 1
  __silt__take_last__from=$((__silt__take_last__count - $3))
  if [ "$__silt__take_last__from" -lt 0 ]; then
    warn "silt: take_last asked for $3 elements and the list has $__silt__take_last__count"
    __silt__take_last__from=0
  fi

  silt__slice "$1" "$2" "$__silt__take_last__from" "$__silt__take_last__count"
}
