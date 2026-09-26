#!/bin/sh

# The constants: the line count that hands a document to the awk tier, and the characters a shell literal cannot spell.

: <<'CONST'
The line count past which a document is the awk tier's, measured on dash and
bash --posix on 2026-09-26: the split stays under the cost of one awk start
to about 1,700 lines under bash and past 4,000 under dash.
CONST
__silt__THRESHOLD=1000

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
