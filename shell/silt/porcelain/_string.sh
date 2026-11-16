#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/string.sh: @string.
FRAGMENT

: <<'PUB_FUN'
Answers the text at a path the way jq -r would: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
nothing holds or a collection.

Given several paths, reads the first path that holds a value that is not a
null. Given --default, answers that text wherever the paths hold nothing, a
null or a collection.

  doc="$(cat <<'SILT'
  0."suites":map
  1."unit":map
  2."runner":str="bats"
  2."tests":map
  3."test/a.bats":map
  4."reads":list
  5.0:str="lib/a.sh"
  SILT
  )"
  @string runner "$doc" .suites.unit.runner   ->  runner=bats
  @string runner "$doc" .runner .suites.unit.runner   ->  runner=bats
  @string runner "$doc" .suites.other.runner --default bats   ->  runner=bats

  The same, with each SILT document written as JSON:

    @string runner {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .suites.unit.runner   ->  runner=bats
    @string runner {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .runner .suites.unit.runner   ->  runner=bats
    @string runner {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .suites.other.runner --default bats   ->  runner=bats

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $@  The path, or several paths
  --default  The text to answer when no path holds a scalar
PUB_FUN
@string() {
  silt__string "$@"
}
