#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/get.sh: @get.
FRAGMENT

: <<'PUB_FUN'
Answers the value at a path as a SILT document of its own: a leaf becomes one
keyless line, a collection becomes its members at depth 0, an empty
collection or a null its one keyless line. Answers the empty string for a
path nothing holds, which is not a SILT document.

Given several paths, answers the value at the first path that holds a value
that is not a null. When no path does, answers the document after
--default, or without --default what the last path holds.

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
  @get runner "$doc" .suites.unit.runner   ->  runner='0.:str="bats"'

  The same, with each SILT document written as JSON:

    @get runner {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .suites.unit.runner   ->  runner="bats"

  @get reads "$doc" .suites.unit.tests

  reads is:
    0."test/a.bats":map
    1."reads":list
    2.0:str="lib/a.sh"

  The same, with each SILT document written as JSON:

    @get reads {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .suites.unit.tests   ->  reads={"test/a.bats":{"reads":["lib/a.sh"]}}

  @get nodes "$doc" .nodes .edges --default '0.:list'   ->  nodes='0.:list'

  The same, with each SILT document written as JSON:

    @get nodes {"suites":{"unit":{"runner":"bats","tests":{"test/a.bats":{"reads":["lib/a.sh"]}}}}} .nodes .edges --default []   ->  nodes=[]

args:
  $1  The name of the variable to answer in
  $2  The SILT document
  $@  The path, or several paths
  --default  The SILT document to answer when no path holds a value
PUB_FUN
@get() {
  silt__get "$@"
}
