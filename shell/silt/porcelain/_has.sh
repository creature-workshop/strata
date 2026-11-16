#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/has.sh: @has.
FRAGMENT

: <<'PUB_FUN'
Answers true when the SILT document holds a value at the path, a null
included, and false otherwise.

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $3  The path
PUB_FUN
@has() {
  silt__has "$@"
}
