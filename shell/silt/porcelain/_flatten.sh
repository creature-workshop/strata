#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/flatten.sh: @flatten.
FRAGMENT

: <<'PUB_FUN'
Answers one map for a tree of named nodes. The tree is a map from a name
to a node, and a node can hold more nodes under the child key. Each key of
the answer is the names on the way to a node, joined by the separator.
Each value is the node without its child key. A node comes before the
nodes under it.

  tree="$(cat <<'SILT'
  0."lib":map
  1."owner":str="a"
  1."areas":map
  2."log":map
  3."owner":str="b"
  SILT
  )"
  @flatten flat "$tree" areas

  flat is:
    0."lib":map
    1."owner":str="a"
    0."lib.log":map
    1."owner":str="b"

  The same, with each SILT document written as JSON:

    @flatten flat {"lib":{"owner":"a","areas":{"log":{"owner":"b"}}}} areas   ->  flat={"lib":{"owner":"a"},"lib.log":{"owner":"b"}}

args:
  $1  The name of the variable to answer in
  $2  The tree, a map
  $3  The child key
  $4  The separator; a dot when not given
PUB_FUN
@flatten() {
  silt__flatten "$@"
}
