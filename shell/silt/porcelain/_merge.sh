#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/merge.sh: @merge.
FRAGMENT

: <<'PUB_FUN'
Answers the first map with the second laid over it, one level deep: a key
both hold takes the second map's value, in the first map's place, and a key
only the second holds is added after the first's members, in the second's
order. A value that is itself a map is replaced whole, not merged.

  defaults="$(cat <<'SILT'
  0."a":int=1
  0."b":int=2
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."b":int=3
  0."c":int=4
  SILT
  )"
  @merge doc "$defaults" "$overrides"

  doc is:
    0."a":int=1
    0."b":int=3
    0."c":int=4

  The same, with each SILT document written as JSON:

    @merge doc {"a":1,"b":2} {"b":3,"c":4}   ->  doc={"a":1,"b":3,"c":4}

--lists says what happens to two lists under the same key:

  replace  the second list is used; this is the default
  concat   the second list's elements follow the first's
  union    as concat, and then every element that is the same value as an
           earlier one is dropped, as @unique does

  defaults="$(cat <<'SILT'
  0."l":list
  1.0:int=1
  SILT
  )"
  overrides="$(cat <<'SILT'
  0."l":list
  1.0:int=2
  SILT
  )"
  @merge doc "$defaults" "$overrides" --lists concat

  doc is:
    0."l":list
    1.0:int=1
    1.1:int=2

  The same, with each SILT document written as JSON:

    @merge doc {"l":[1]} {"l":[2]} --lists concat   ->  doc={"l":[1,2]}

With replace, this runs in awk whatever the maps' size.

args:
  $1       The name of the variable to answer in
  $2       The map
  $3       The map laid over it
  --lists  replace, concat or union
PUB_FUN
@merge() {
  silt__merge "$@"
}
