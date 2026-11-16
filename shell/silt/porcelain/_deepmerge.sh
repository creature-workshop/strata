#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/deepmerge.sh: @deepmerge.
FRAGMENT

: <<'PUB_FUN'
Answers the first map with the second laid over it, at every depth. For a
key that both hold: two maps are merged in the same way, and for any other
pair the second map's value is used. A key that only the second holds is
added after the first's members. With the default for lists, the answer is
what jq gives for `$a * $b`.

  defaults="$(cat <<'SILT'
  0."a":map
  1."x":int=1
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."a":map
  1."y":int=2
  SILT
  )"
  @deepmerge doc "$defaults" "$overrides"

  doc is:
    0."a":map
    1."x":int=1
    1."y":int=2

  The same, with each SILT document written as JSON:

    @deepmerge doc {"a":{"x":1}} {"a":{"y":2}}   ->  doc={"a":{"x":1,"y":2}}

--lists says what happens to two lists under the same key:

  replace  the second list is used; this is the default
  concat   the second list's elements follow the first's
  union    as concat, and then every element that is the same value as an
           earlier one is dropped, as @unique does

args:
  $1       The name of the variable to answer in
  $2       The map
  $3       The map laid over it
  --lists  replace, concat or union
PUB_FUN
@deepmerge() {
  silt__deepmerge "$@"
}
