#!/usr/bin/env bats
# The golden fixtures of the SILT reader, under test/fixtures/silt/, run
# through shell-goldens at shell/.golden. One fileset is one case, in a
# directory of its own named for it, test/fixtures/silt/<name>/: name.txt is
# its name and the test's name in the log, about.txt explains it in plain
# words and prints when the case fails, calls.txt lists verbs to run with
# their one argument, document.silt is the document they run against
# (absent, the module's own <name>.fixture.silt), and expected.txt is the
# transcript test/silt-transcript.sh writes. A document a call reads by
# name, <file>.json, .yaml, .toml, .strh or .strt, has a directory of its
# own inside the fileset whose call reads it, <name>/<document>/, with a
# name.txt and an about.txt of its own beside it, and a test checks that
# each does; the call names it from the fileset, "from_toml crlf/crlf.toml".
# A document two filesets read is in both.
#
# Every fileset is registered as a test of its own under bash, dash and
# /bin/sh, on the shell tier and again with every walk handed to awk, so a
# new case is a new directory, test/fixtures/silt/<name>/, holding its
# fileset, and no new test code.
# UPDATE_GOLDENS=1 rewrites the expected.txt files from the live answers
# under bash on the shell tier, to be read before they are committed.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
GOLDEN_FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"
load "$REPO/shell/.golden/shell/golden/bats.sh"

# The transcript of a fileset's calls under a variant "<tier> tier under
# <shell>": the script run by that shell, with every walk on that tier.
transcript() {
  local tier="${2%% *}" shell="${2##* }"
  SILT_THRESHOLD="$(threshold_of "$tier")" "$shell" "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$GOLDEN_FIXTURES/$1/calls.txt" "$(document_of "$1")"
}

# The threshold that puts every walk on a tier: the library's own for the
# shell tier, 0 for awk.
threshold_of() {
  if [ "$1" = awk ]; then
    printf '0'
  else
    printf '1000000'
  fi
}

# The document a fileset's calls run against: document.silt beside the calls,
# else the module's own <name>.fixture.silt, else nothing.
document_of() {
  if [ -f "$GOLDEN_FIXTURES/$1/document.silt" ]; then
    printf '%s' "$GOLDEN_FIXTURES/$1/document.silt"
  elif [ -f "$REPO/shell/silt/$1.fixture.silt" ]; then
    printf '%s' "$REPO/shell/silt/$1.fixture.silt"
  fi
}

# Every document a call reads by name carries a name and an about of its own.
@test "golden documents: every .json, .yaml, .toml, .strh and .strt under the fixtures has a name.txt and an about.txt beside it" {
  local missing
  missing="$(golden__unnamed_documents json yaml toml strh strt)"
  [ -z "$missing" ] || fail "documents with no name or about: $missing"
}

golden__register transcript \
  'shell tier under bash' 'shell tier under dash' 'shell tier under sh' \
  'awk tier under bash' 'awk tier under dash' 'awk tier under sh'
