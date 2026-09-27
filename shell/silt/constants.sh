#!/bin/sh

: <<'MODULE'
Constants every file in the library reads.
MODULE

: <<'CONST'
The line count past which a document belongs to the awk tier. The split
stays cheaper than one awk start to about 1,700 lines under bash and past
4,000 under dash, so 1,000 leaves room under both.
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

: <<'CONST'
The double quote, named so no line has to spell it escaped.
CONST
__silt__QUOTE='"'

: <<'CONST'
The backslash, named so no line has to spell it doubled.
CONST
__silt__BACKSLASH=\\

