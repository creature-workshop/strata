#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names for the ends and the slices of a list: @first, @last, @pop,
@shift, @take, @take_last and @slice.
FRAGMENT

: <<'PUB_FUN'
Answers the first element of a list as a SILT document of its own. Answers the
empty string for an empty list, which is not a SILT document. Refuses a
document that is not a list.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @first doc "$list"   ->  doc='0.:str="a"'

  The same, with each SILT document written as JSON:

    @first doc ["a","b"]   ->  doc="a"

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
@first() {
  silt__first "$@"
}

: <<'PUB_FUN'
Answers the last element of a list as a SILT document of its own. Answers the
empty string for an empty list, which is not a SILT document. Refuses a
document that is not a list.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @last doc "$list"   ->  doc='0.:str="b"'

  The same, with each SILT document written as JSON:

    @last doc ["a","b"]   ->  doc="b"

args:
  $1  Name of the variable that receives the result
  $2  The list
PUB_FUN
@last() {
  silt__last "$@"
}

: <<'PUB_FUN'
Answers the last element of a list and, when the caller names a second
variable, the list without that element. For an empty list the element is
the empty string, which is not a SILT document, and the rest is the empty
list. Refuses a document that is not a list.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @pop last rest "$list"   ->  last='0.:str="b"'  rest='0.0:str="a"'

  The same, with each SILT document written as JSON:

    @pop last rest ["a","b"]   ->  last="b"  rest=["a"]

  @pop last "$list"   ->  last='0.:str="b"'

  The same, with each SILT document written as JSON:

    @pop last ["a","b"]   ->  last="b"

args:
  $1  Name of the variable that receives the last element
  $2  Name of the variable that receives the rest of the list, when given
  $3  The list
PUB_FUN
@pop() {
  silt__pop "$@"
}

: <<'PUB_FUN'
Answers the first element of a list and, when the caller names a second
variable, the list without that element, numbered from 0. For an empty list
the element is the empty string, which is not a SILT document, and the rest
is the empty list. Refuses a document that is not a list.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @shift first rest "$list"   ->  first='0.:str="a"'  rest='0.0:str="b"'

  The same, with each SILT document written as JSON:

    @shift first rest ["a","b"]   ->  first="a"  rest=["b"]

  @shift first "$list"   ->  first='0.:str="a"'

  The same, with each SILT document written as JSON:

    @shift first ["a","b"]   ->  first="a"

args:
  $1  Name of the variable that receives the first element
  $2  Name of the variable that receives the rest of the list, when given
  $3  The list
PUB_FUN
@shift() {
  silt__shift "$@"
}

: <<'PUB_FUN'
Answers the first <count> elements of a list. When the list has fewer, it
answers the whole list and logs a warning. Refuses a SILT document that is
not a list, and a count that is not a whole number of 0 or more.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @take doc "$list" 1   ->  doc='0.0:str="a"'

  The same, with each SILT document written as JSON:

    @take doc ["a","b"] 1   ->  doc=["a"]

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  How many elements to take
PUB_FUN
@take() {
  silt__take "$@"
}

: <<'PUB_FUN'
Answers the last <count> elements of a list, numbered from 0. When the list
has fewer, it answers the whole list and logs a warning. Refuses a SILT
document that is not a list, and a count that is not a whole number of 0 or
more.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  SILT
  )"
  @take_last doc "$list" 1   ->  doc='0.0:str="b"'

  The same, with each SILT document written as JSON:

    @take_last doc ["a","b"] 1   ->  doc=["b"]

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  How many elements to take
PUB_FUN
@take_last() {
  silt__take_last "$@"
}

: <<'PUB_FUN'
Answers the elements of a list from the index <from> up to, but not
including, the index <to>, as a list numbered from 0. An index past the end
of the list takes what there is, so the answer may be shorter than asked, or
the empty list. Refuses a SILT document that is not a list, and an index
that is not a whole number of 0 or more.

  list="$(cat <<'SILT'
  0.0:str="a"
  0.1:str="b"
  0.2:str="c"
  SILT
  )"
  @slice doc "$list" 1 3

  doc is:
    0.0:str="b"
    0.1:str="c"

  The same, with each SILT document written as JSON:

    @slice doc ["a","b","c"] 1 3   ->  doc=["b","c"]

args:
  $1  Name of the variable that receives the result
  $2  The list
  $3  The index of the first element to keep
  $4  The index after the last element to keep
PUB_FUN
@slice() {
  silt__slice "$@"
}
