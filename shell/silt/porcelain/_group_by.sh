#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/group_by.sh: @group_by.
FRAGMENT

: <<'PUB_FUN'
Answers a list of lists. Each inner list holds the elements whose values at
the path are the same, in the order the list holds them. The inner lists are
in the order of those values, as @sort_by orders them. Given several paths,
two elements are in the same inner list when their values are the same at
every path. Given no path, the elements themselves are compared. The empty
list answers the empty list. Refuses a SILT document that is not a list, and
a map or a list at a path. This runs in awk whatever the list's size.

  list="$(cat <<'SILT'
  0.0:str="b"
  0.1:str="a"
  0.2:str="b"
  SILT
  )"
  @group_by doc "$list"

  doc is:
    0.0:list
    1.0:str="a"
    0.1:list
    1.0:str="b"
    1.1:str="b"

  The same, with each SILT document written as JSON:

    @group_by doc ["b","a","b"]   ->  doc=[["a"],["b","b"]]

  rows="$(cat <<'SILT'
  0.0:map
  1."suite":str="unit"
  1."file":str="a.bats"
  0.1:map
  1."suite":str="e2e"
  1."file":str="b.bats"
  0.2:map
  1."suite":str="unit"
  1."file":str="c.bats"
  SILT
  )"
  @group_by by_suite "$rows" .suite

  by_suite is:
    0.0:list
    1.0:map
    2."suite":str="e2e"
    2."file":str="b.bats"
    0.1:list
    1.0:map
    2."suite":str="unit"
    2."file":str="a.bats"
    1.1:map
    2."suite":str="unit"
    2."file":str="c.bats"

  The same, with each SILT document written as JSON:

    @group_by by_suite [{"suite":"unit","file":"a.bats"},{"suite":"e2e","file":"b.bats"},{"suite":"unit","file":"c.bats"}] .suite   ->  by_suite=[[{"suite":"e2e","file":"b.bats"}],[{"suite":"unit","file":"a.bats"},{"suite":"unit","file":"c.bats"}]]

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
@group_by() {
  silt__group_by "$@"
}
