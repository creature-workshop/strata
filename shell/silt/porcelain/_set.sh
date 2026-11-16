#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/set.sh: @set, @patch.
FRAGMENT

: <<'PUB_FUN'
Puts a value at a path, or each of several values at its path. If a member
is already there, it is replaced along with everything under it. If not, the
value is added at the end of its parent, and any missing parents on the way
are created: a map, or a list when the next path segment is an index. An
empty path answers the value itself.

Refuses when the SILT document is not a map or a list, when the path runs
through a scalar, or when the path names a list index that does not exist;
push is what grows a list.

  @set doc '0."a":int=1' .b '0.:int=2'

  doc is:
    0."a":int=1
    0."b":int=2

  The same, with each SILT document written as JSON:

    @set doc {"a":1} .b 2   ->  doc={"a":1,"b":2}

  @set doc '0."a":int=1' .a.b '0.:int=2'    ->  refused: not a collection at "a"

  The same, with each SILT document written as JSON:

    @set doc {"a":1} .a.b 2   ->  refused: not a collection at "a"

Given several pairs, places them one after another, so a later pair sees
what an earlier pair placed.

  @set doc '0.:map' .a '0.:int=1' .b '0.:int=2'

  doc is:
    0."a":int=1
    0."b":int=2

  The same, with each SILT document written as JSON:

    @set doc {} .a 1 .b 2   ->  doc={"a":1,"b":2}

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $3  The path
  $4  The value, a SILT document
  $@  More paths and values, pair by pair
PUB_FUN
@set() {
  silt__set "$@"
}

: <<'PUB_FUN'
Puts each value that is given at its path, as @set does, and leaves
out every pair whose value is the empty string. A caller can pass all the
fields it might change, and only the ones that have a value are written.

  @patch doc '0."a":int=1' .a '' .b '0.:int=2'

  doc is:
    0."a":int=1
    0."b":int=2

  The same, with each SILT document written as JSON:

    @patch doc {"a":1} .a '' .b 2   ->  doc={"a":1,"b":2}

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $@  A path and a value, pair by pair
PUB_FUN
@patch() {
  silt__patch "$@"
}
