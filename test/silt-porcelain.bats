#!/usr/bin/env bats
# The porcelain (shell/silt/porcelain/api.sh): an `@` name for every `silt__`
# verb, giving what the verb gives.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

setup() {
  export SILT_DIR="$REPO/shell/silt"
}

# Prints the names of the functions that begin with a prefix, without the
# prefix, sorted.
names_under() {
  declare -F | awk '{ print $3 }' | grep "^$1" | sed "s/^$1//" | sort
}

@test "porcelain: every silt__ verb has an @ name, and every @ name a silt__ verb" {
  # shellcheck source=../shell/silt/porcelain/api.sh
  . "$REPO/shell/silt/porcelain/api.sh"

  assert_equal "$(names_under @)" "$(names_under silt__)"
}

@test "porcelain: an @ name gives what its silt__ verb gives" {
  # shellcheck source=../shell/silt/porcelain/api.sh
  . "$REPO/shell/silt/porcelain/api.sh"

  @str name lib
  @obj cfg name "$name"
  @get entry "$cfg" .name
  @string text "$cfg" .name
  @to_json json "$cfg"

  silt__get expected "$cfg" .name
  assert_equal "$entry" "$expected"
  assert_equal "$text" lib
  assert_equal "$json" '{"name":"lib"}'
}

@test "porcelain: an @ name fails as its silt__ verb fails" {
  # shellcheck source=../shell/silt/porcelain/api.sh
  . "$REPO/shell/silt/porcelain/api.sh"

  run @get '1bad' '0.:null' .name

  assert_failure
  assert_output --partial "not a variable name"
}

@test "porcelain: SILT's api.sh does not define the @ names" {
  # shellcheck source=../shell/silt/api.sh
  . "$REPO/shell/silt/api.sh"

  run command -v @get

  assert_failure
}
