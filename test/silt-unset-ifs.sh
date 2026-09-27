#!/bin/sh
# Checks that SILT works for a caller that has IFS unset and runs under
# set -u, and that it leaves IFS the way it found it.
#
# A shell with IFS unset splits on its default characters. shellops' command
# line parser leaves IFS that way, so every shellops command calls SILT like
# this.
#
# The script runs a verb that walks a document, a verb that builds one, and
# a verb that splits text, first with IFS unset and then with IFS set to a
# colon. After each verb it checks the answer and checks IFS. It prints each
# check that fails and exits non-zero if any did.
#
# Usage: <shell> test/silt-unset-ifs.sh <api.sh>

set -u

FAILED=0

main() {
  require_usage "$@"
  load_library "$1"

  unset IFS
  check_verbs 'unset'

  IFS=':'
  check_verbs 'a colon'

  report
}

# Exits with a usage error unless the library is named.
require_usage() {
  if [ "$#" -lt 1 ]; then
    printf 'usage: silt-unset-ifs.sh <api.sh>\n' >&2
    exit 2
  fi
}

# Loads SILT and tells it where it lives, for shells that cannot tell.
load_library() {
  export SILT_DIR="${1%/*}"
  # shellcheck source=../shell/silt/api.sh
  . "$1"
}

# Runs the three verbs and checks each answer and IFS after it.
#
#   $1  How IFS was left before the verbs ran, for the failure message
check_verbs() {
  silt__get ANSWER '0."a":map
1."b":int=1' .a.b
  check 'silt__get' "$1" "$ANSWER" '0.:int=1'

  silt__push ANSWER '0.:list' '0.:str="x"'
  check 'silt__push' "$1" "$ANSWER" '0.0:str="x"'

  silt__split ANSWER 'a,b' ','
  check 'silt__split' "$1" "$ANSWER" '0.0:str="a"
0.1:str="b"'
}

# Records a failure if the answer is wrong or IFS is not as it was left.
#
#   $1  The verb
#   $2  How IFS was left before the verb ran
#   $3  The verb's answer
#   $4  The answer it should have given
check() {
  if [ "$3" != "$4" ]; then
    printf '## %s with IFS %s answered:\n%s\n' "$1" "$2" "$3"
    FAILED=1
  fi
  if [ "${IFS-unset}" != "$(expected_ifs "$2")" ]; then
    printf '## %s changed IFS, which was %s, to: %s\n' "$1" "$2" "${IFS-unset}"
    FAILED=1
  fi
}

# Prints what IFS should hold, or the word unset.
#
#   $1  How IFS was left: "unset" or "a colon"
expected_ifs() {
  if [ "$1" = 'unset' ]; then
    printf 'unset'
  else
    printf ':'
  fi
}

# Prints the result and exits non-zero if any check failed.
report() {
  if [ "$FAILED" -ne 0 ]; then
    printf 'silt-unset-ifs: FAILED.\n' >&2
    exit 1
  fi
  printf 'silt-unset-ifs: passed. SILT works with IFS unset and leaves IFS as it found it.\n'
}

main "$@"
