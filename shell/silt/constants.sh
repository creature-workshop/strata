#!/bin/sh

: <<'MODULE'
Constants every file in the library reads.
MODULE

: <<'CONST'
The line count past which a verb hands its document to the awk tier, read
from SILT_THRESHOLD when the environment sets it, so a suite can run every
case on both sides of it. test/silt-threshold.sh measures it: a get over the
last key crosses one awk start at about 120 lines under bash and about 600
under dash, and the constant follows the slower shell.
CONST
__silt__THRESHOLD="${SILT_THRESHOLD:-128}"

: <<'CONST'
The characters the shell cannot spell in a literal: a newline for joining
lines, and the four control characters JSON names by letter.
CONST
__silt__NL='
'
__silt__TAB="$(printf '\t')"
__silt__CR="$(printf '\r')"
__silt__BS="$(printf '\b')"
__silt__FF="$(printf '\f')"

: <<'CONST'
The record separator: the line holding it alone ends a member's block in
what the awk tier writes for each.
CONST
__silt__RS="$(printf '\036')"

: <<'CONST'
The double quote, named so no line has to spell it escaped.
CONST
__silt__QUOTE='"'

: <<'CONST'
The backslash, named so no line has to spell it doubled.
CONST
__silt__BACKSLASH=\\


: <<'CONST'
The three backticks that open and close a Markdown code fence.
CONST
__silt__FENCE='```'
