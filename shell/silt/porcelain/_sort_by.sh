#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/sort_by.sh: @sort_by.
FRAGMENT

: <<'PUB_FUN'
Answers the list with its elements in the order of the value at a path
inside each, renumbered from 0. Given several paths, orders by the value at
the first path, and orders the elements that tie there by the value at the
next. Given no path, orders by the elements themselves. Elements that tie
at every path keep the order the list holds them in.

Values are ordered by kind first: a null or a path that holds nothing, then
false, then true, then a number, then a text. Numbers are ordered by size.
Texts are ordered byte by byte, a str read as the text it spells. Refuses a
document that is not a list, and a map or a list at a path. This runs in
awk whatever the list's size.

  list="$(cat <<'SILT'
  0.0:map
  1."at":int=2
  0.1:map
  1."at":int=1
  SILT
  )"
  @sort_by doc "$list" .at

  doc is:
    0.0:map
    1."at":int=1
    0.1:map
    1."at":int=2

  The same, with each SILT document written as JSON:

    @sort_by doc [{"at":2},{"at":1}] .at   ->  doc=[{"at":1},{"at":2}]

  queue="$(cat <<'SILT'
  0.0:map
  1."iid":int=9
  1."ready_at":int=2
  0.1:map
  1."iid":int=7
  1."ready_at":int=2
  0.2:map
  1."iid":int=8
  1."ready_at":int=1
  SILT
  )"
  @sort_by ordered "$queue" .ready_at .iid

  ordered is:
    0.0:map
    1."iid":int=8
    1."ready_at":int=1
    0.1:map
    1."iid":int=7
    1."ready_at":int=2
    0.2:map
    1."iid":int=9
    1."ready_at":int=2

  The same, with each SILT document written as JSON:

    @sort_by ordered [{"iid":9,"ready_at":2},{"iid":7,"ready_at":2},{"iid":8,"ready_at":1}] .ready_at .iid   ->  ordered=[{"iid":8,"ready_at":1},{"iid":7,"ready_at":2},{"iid":9,"ready_at":2}]

args:
  $1  The name of the variable to answer in
  $2  The list
  $@  The paths into each element
PUB_FUN
@sort_by() {
  silt__sort_by "$@"
}
