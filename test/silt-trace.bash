#!/usr/bin/env bash
# Runs a script with bash's trace on descriptor 9, one line per command as
# "+cov <file>:<line>:<function> <command>", for test/silt-coverage.sh. The
# trace settings are made here, inside the traced shell, because bash ignores
# a PS4 it inherits when it runs as root, which it does in CI.
#
# Usage: bash test/silt-trace.bash <script> [<argument>...] 9>><trace file>

SCRIPT="$1"
shift

BASH_XTRACEFD=9
PS4='+cov ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]:-} '
set -x
. "$SCRIPT" "$@"
