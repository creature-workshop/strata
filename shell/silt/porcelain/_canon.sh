#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/canon.sh: @canon, @equals.
FRAGMENT

: <<'PUB_FUN'
Answers the SILT document with every map's members in canonical order, the
order RFC 8785 gives: by the keys' UTF-16 code units, which is what jq -S
and the canonical JSON libraries agree on. Lists keep their order and every
line keeps its text, so two maps that hold the same members come out the
same bytes. This runs in awk whatever the document's size, since the shell
cannot order two strings.

  map="$(cat <<'SILT'
  0."b":int=1
  0."a":int=2
  SILT
  )"
  @canon doc "$map"

  doc is:
    0."a":int=2
    0."b":int=1

  The same, with each SILT document written as JSON:

    @canon doc {"b":1,"a":2}   ->  doc={"a":2,"b":1}

args:
  $1  The name of the variable to answer in
  $2  The SILT document
PUB_FUN
@canon() {
  silt__canon "$@"
}

: <<'PUB_FUN'
Answers true when two documents are the same value and false otherwise:
the same bytes are the same value at once, and two documents that differ
as bytes are put in canonical order before they are compared, so a map
built in one order equals the same map built in another.

  map="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  other="$(cat <<'SILT'
  0."b":int=2
  0."a":int=1
  SILT
  )"
  @equals same "$map" "$other"   ->  same=true

  The same, with each SILT document written as JSON:

    @equals same {"a":1,"b":2} {"b":2,"a":1}   ->  same=true

args:
  $1  The name of the variable to answer in
  $2  One document
  $3  The other
PUB_FUN
@equals() {
  silt__equals "$@"
}
