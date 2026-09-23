# ADR.17: A toc entry carries its document's digest, and the digest of a header names the corpus's whole content

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/20
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1186
- Implementation: not started

## Context

A corpus's seeds identify it and verify nothing. A document rewritten in
place, or an ancestor corpus quietly changed after it was read, leaves every
id intact and no trace. zstd's frame checksum catches a corrupted frame and
nothing more: it is a checksum, made to notice accidental damage, not a
digest, made so that no other content produces it.

Git names content by its digest, and OCI images write one as
`<algorithm>:<hex>` so the algorithm can change under the same field. A tree
of digests, each parent's covering its children's, is Merkle's, and it lets
one value stand for everything beneath it.

## Decision

- A **digest** is written `sha256:` followed by the sixty-four lowercase hex
  characters of SHA-256 over the bytes named. The algorithm is part of the
  value, so a later grammar may add another by appending.
- A toc entry ([ADR.10@opx](../000010-the-toc/adr.md)) carries `digest`: the
  digest of the document's `.strt` text under its header, the bytes a
  stratum's frame holds ([ADR.15@opx](../000015-the-pack/adr.md)). The writer
  keeps it current with `lines`.

  ```
  2."path":str="jobs/2026-09"
  2."lines":int=41207
  2."digest":str="sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
  ```

- A **corpus's digest** is the digest of its header's `.strh` text without
  the `contents` key. Since the toc holds every document's digest, the
  header's digest names the corpus's whole content as it stood when the
  header was written.
- A reader that verifies MUST refuse a document whose digest differs from
  its entry.
- A reader that cannot compute SHA-256 MUST still read, and MUST refuse only
  to verify.

## Consequences

Substitution is caught where corruption already was. A document decoded
from a frame is checked against its entry before it is trusted, and a
history entry ([ADR.18@opx](../000018-the-history/adr.md)) that names an
input by its corpus digest pins the exact content that was read, every
document included, in one value.

The digest is over terse bytes, so it does not change when the header
grows, since a code never changes, nor when a document is extracted, since
the terse form carries no LID. It does depend on the index, so the same
content under two headers has two digests: a digest names a document in its
corpus, not in the abstract.

The header cannot carry its own digest. Whoever refers to a corpus records
it: a history entry, a file name, a ticket.

`awk` has no SHA-256. The fallback verifies with a `sha256sum` beside it,
and reads without one.
