#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/push.sh: @push.
FRAGMENT

: <<'PUB_FUN'
Appends documents to the end of a list, numbering them on from its last
index. Given --at and a path, appends them to the list at that path inside
the SILT document, and answers the whole document.

  @push doc '0.0:str="a"' '0.:int=2'

  doc is:
    0.0:str="a"
    0.1:int=2

  The same, with each SILT document written as JSON:

    @push doc ["a"] 2   ->  doc=["a",2]

  suite="$(cat <<'SILT'
  0."tests":list
  1.0:str="a"
  SILT
  )"
  @push doc "$suite" --at .tests '0.:int=2'

  doc is:
    0."tests":list
    1.0:str="a"
    1.1:int=2

  The same, with each SILT document written as JSON:

    @push doc {"tests":["a"]} --at .tests 2   ->  doc={"tests":["a",2]}

args:
  $1    The name of the variable to answer in
  $2    The list, or with --at the SILT document that holds it
  --at  The path of the list inside the SILT document
  $@    The SILT documents to append
PUB_FUN
@push() {
  silt__push "$@"
}
