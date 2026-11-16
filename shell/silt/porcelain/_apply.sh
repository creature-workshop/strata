#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/apply.sh: @apply.
FRAGMENT

: <<'PUB_FUN'
Runs a command once, with the text of each element of a list added after
the command's own arguments, and returns the command's status. Each element
is read the way @string reads it: a str unquoted, another scalar as
written. Use it for a command that takes any number of files or names.

  files="$(cat <<'SILT'
  0.0:str="a.sh"
  0.1:str="b.sh"
  SILT
  )"
  @apply "$files" git add --   ->  runs: git add -- a.sh b.sh

  The same, with each SILT document written as JSON:

    @apply ["a.sh","b.sh"] git add --   ->  runs: git add -- a.sh b.sh

args:
  $1  The list
  $@  The command and its own arguments
PUB_FUN
@apply() {
  silt__apply "$@"
}
