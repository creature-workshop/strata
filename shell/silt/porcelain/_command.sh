#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/command.sh: @succeeds, @fails.
FRAGMENT

: <<'PUB_FUN'
Runs a command and answers true when it exits with status 0, and false
otherwise. The command reads the caller's stdin.

  kind=map
  @succeeds yes [ "$kind" = map ]   ->  yes=true
  @succeeds yes [ "$kind" = list ]   ->  yes=false

args:
  $1  The name of the variable to answer in
  $@  The command and its arguments
PUB_FUN
@succeeds() {
  silt__succeeds "$@"
}

: <<'PUB_FUN'
Runs a command and answers true when it exits with a status other than 0,
and false when it exits with 0. The command reads the caller's stdin.

  @fails drifted ./install.sh --check   ->  drifted=true when the check fails

args:
  $1  The name of the variable to answer in
  $@  The command and its arguments
PUB_FUN
@fails() {
  silt__fails "$@"
}
