# ADR.22: A line is at most 2^24 bytes, and a writer refuses a value that would exceed it

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/25
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1228
- Implementation: not started

## Context

A `str` is a JSON string literal on one line
([ADR.3@opx](../000003-natural-primitives/adr.md)), so a file stored as a
value, a compiled unit's source for one, is a line as long as the file. Some
`awk` implementations hold a record in a fixed buffer and cannot read past
it, and the `awk` reader is the portable fallback. A line one reader takes
and another cannot is an implementation-dependent difference.

Measured on 2026-09-22: `mawk` 1.3.4 and BusyBox 1.36 `awk` both read a
line of 16 MiB whole.

## Decision

- A line, its LF included, is at most 16,777,216 bytes, 2^24.
- A reader MUST accept any line up to that length, and MUST refuse a longer
  one, naming the line.
- A writer MUST refuse a value whose line would be longer, as it refuses an
  `int` outside 64 bits. It MUST NOT split the value.

## Consequences

Every conforming reader reads every conforming document. An `awk` whose
record buffer is smaller does not conform, and the fallback says which
`awk` it needs.

A value larger than a line is not a value. It is a blob beside the corpus,
named by a `ref` that carries its digest
([ADR.24@opx](../000024-the-ref/adr.md)). Splitting it into chunks would
change its type, and a reader would have to know to join them.

Sixteen MiB is a bound, not a target. A document of a million short lines
is what the format is for; a document of one long line is what a file is
for.

The bound is a grammar constant, so raising it is a later grammar and the
version carries it ([ADR.14@opx](../000014-the-version/adr.md)).
