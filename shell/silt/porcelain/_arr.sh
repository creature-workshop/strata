#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/arr.sh: @arr.
FRAGMENT

: <<'PUB_FUN'
Builds a list from the SILT documents given, in order, indexed from 0. With no
documents it builds the empty list.

  @arr doc '0.:str="a"' '0.:int=2'

  doc is:
    0.0:str="a"
    0.1:int=2

  The same, with each SILT document written as JSON:

    @arr doc "a" 2   ->  doc=["a",2]

args:
  $1  The name of the variable to answer in
  $@  The SILT documents
PUB_FUN
@arr() {
  silt__arr "$@"
}
