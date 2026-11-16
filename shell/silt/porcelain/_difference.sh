#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/difference.sh: @difference.
FRAGMENT

: <<'PUB_FUN'
Answers the first list without the elements that are also in the second:
the set difference, first minus second. The elements that stay keep their
order. An element the first list repeats stays as often as it was there,
so the answer is a list and not a set. Two elements are the same when
@equals says so, which makes the int 1 and the str "1" different. This
runs in awk whatever the lists' size.

Written as JSON:

  [1, 2, 3]       minus [2]      ->  [1, 3]
  [1, 2, 2, 3, 1] minus [2]      ->  [1, 3, 1]
  [1, 2]          minus ["1"]    ->  [1, 2]

As it is called:

  numbers="$(cat <<'SILT'
  0.0:int=1
  0.1:int=2
  0.2:int=3
  SILT
  )"
  taken="$(cat <<'SILT'
  0.0:int=2
  SILT
  )"
  @difference left "$numbers" "$taken"

  left is:
    0.0:int=1
    0.1:int=3

args:
  $1  The name of the variable to answer in
  $2  The list
  $3  The list whose values are taken out
PUB_FUN
@difference() {
  silt__difference "$@"
}
