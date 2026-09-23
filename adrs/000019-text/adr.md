# ADR.19: A line ends in LF, a document ends in one, and a reader refuses a byte-order mark and normalises nothing

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/22
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1225
- Implementation: not started

## Context

[ADR.2@strata](../000002-one-node-per-line/adr.md) makes a document UTF-8 text,
one node per line, and says nothing of what ends a line, whether the last
line ends at all, what a byte-order mark means, or whether two keys that
look alike under Unicode normalisation are one key.

Every implementation must accept and refuse the same bytes, or a document
that one reads and another rejects is an implementation-dependent
idiosyncrasy of the kind the format exists to rule out. Tolerating is a
choice as much as refusing is, and a tolerant reader makes a stricter one
look broken.

## Decision

- A line ends in one LF byte, and the document's last byte is an LF.
- A document holds no byte below 0x20 but LF. A `str` carries a control
  character as a JSON escape ([ADR.3@strata](../000003-natural-primitives/adr.md)),
  never raw.
- A document MUST be valid UTF-8 and MUST NOT begin with a byte-order mark.
- Keys and values are compared as bytes once their escapes are read. No
  Unicode normalisation is applied, so two keys that differ only in
  composition are two keys.
- A reader MUST refuse a document that breaks any of these, naming the line.
  A translator from a source that allows CRLF, a byte-order mark or raw
  control characters converts on the way in, once.

## Consequences

A file written on a system that ends lines in CRLF is refused, not
tolerated: the translator is where it is fixed, and after that every
reader agrees.

A document cut in the middle of a line is caught by the missing final LF,
which is the case a cut at a line boundary left to the frame and the toc.

Two spellings of the same visible key are two keys, as they are in JSON,
and a writer that wants them to be one normalises before it writes.

A `str` can carry any character, since JSON's escapes carry what a line
cannot hold raw, and a line still splits in one pass because nothing
inside a value can be an LF.
