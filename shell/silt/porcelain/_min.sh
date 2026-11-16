#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/min.sh: @min, @max.
FRAGMENT

: <<'PUB_FUN'
Answers the element of a list that orders first, as a SILT document of its
own. Elements are ordered as @sort_by orders them: by themselves when no
path is given, and by the values at the paths inside each otherwise. Of
several elements that tie, answers the first. Answers the empty string for
an empty list, which is not a SILT document. Refuses a document that is not
a list, and a map or a list where a scalar is compared.

A list of whole numbers given without a path is compared in the shell. Any
other call runs in awk.

  list="$(cat <<'SILT'
  0.0:int=3
  0.1:int=1
  SILT
  )"
  @min doc "$list"   ->  doc='0.:int=1'

  The same, with each SILT document written as JSON:

    @min doc [3,1]   ->  doc=1

  shards="$(cat <<'SILT'
  0.0:map
  1."name":str="b"
  1."started_at":int=20
  0.1:map
  1."name":str="a"
  1."started_at":int=10
  SILT
  )"
  @min first "$shards" .started_at

  first is:
    0."name":str="a"
    0."started_at":int=10

  The same, with each SILT document written as JSON:

    @min first [{"name":"b","started_at":20},{"name":"a","started_at":10}] .started_at   ->  first={"name":"a","started_at":10}

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
@min() {
  silt__min "$@"
}

: <<'PUB_FUN'
Answers the element of a list that orders last, as a SILT document of its own.
Elements are ordered as @sort_by orders them: by themselves when no path is
given, and by the values at the paths inside each otherwise. Of several
elements that tie, answers the last. Answers the empty string for an empty
list, which is not a SILT document. Refuses a document that is not a list,
and a map or a list where a scalar is compared.

A list of whole numbers given without a path is compared in the shell. Any
other call runs in awk.

  list="$(cat <<'SILT'
  0.0:int=3
  0.1:int=1
  SILT
  )"
  @max doc "$list"   ->  doc='0.:int=3'

  The same, with each SILT document written as JSON:

    @max doc [3,1]   ->  doc=3

  areas="$(cat <<'SILT'
  0.0:map
  1."name":str="lib"
  1."length":int=7
  0.1:map
  1."name":str="cli"
  1."length":int=9
  SILT
  )"
  @max longest "$areas" .length

  longest is:
    0."name":str="cli"
    0."length":int=9

  The same, with each SILT document written as JSON:

    @max longest [{"name":"lib","length":7},{"name":"cli","length":9}] .length   ->  longest={"name":"cli","length":9}

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
@max() {
  silt__max "$@"
}
