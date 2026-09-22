# ADR.9: `ecuyer1988-doc-line` draws a LID from L'Ecuyer's two streams, one counting the corpus's documents and the other a document's lines

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/9
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1187
- Implementation: not started

## Context

[ADR.11@opx](../000011-lids-from-number-and-place/adr.md) says what a
generator owes: a LID that is its state, arithmetic under 2^53, no two LIDs
alike in a corpus, and a definition of its own. The default has to serve a
corpus of many large documents.

A single multiplicative generator of 31 bits cannot keep documents apart:
every start is a place on its one cycle, so two documents' stretches of it
overlap sooner or later. Pierre L'Ecuyer's combined generator (Communications
of the ACM, 1988) pairs two such generators with different prime moduli and
combines their outputs. Boost ships it as `ecuyer1988`.

Here the two streams are not combined. One counts documents and the other
counts lines, and the LID is the pair.

## Decision

`ecuyer1988-doc-line` gives line `i` of document `k` the LID

```
doc   = 40692^(k+1) * doc-seed   mod 2147483399
line  = 40014^i     * line-seed  mod 2147483563       i from 1
LID   = hex8(doc) hex8(line)
```

- `doc-seed` is from 1 to 2147483398 and `line-seed` from 1 to 2147483562.
- Each state is written as eight lowercase hex characters, zeros in front.
- Both multipliers are primitive roots of their prime moduli, so `doc` takes
  a different value for every `k` up to 2147483397 and `line` for every `i`
  up to 2147483562. It serves a corpus of up to 2^31 - 2 documents of up to
  2^31 - 2 lines each.
- A conforming implementation draws these LIDs:

  ```
  doc-seed 1299709, line-seed 104729
  document 0, the header:  505b3e7c79c7e1f3  505b3e7c68c84c23  505b3e7c7b970259
  document 1:              67e924b179c7e1f3  67e924b168c84c23  67e924b17b970259
  ```

## Consequences

Equal LIDs need equal `k` and equal `i`, so none repeats in a corpus, by
construction rather than by odds.

A power is taken by repeated squaring, so any line's LID costs about
thirty-one multiplications and none of the LIDs before it. The largest
product is 40692 × 2147483399, under 2^47, so `awk` computes every step
exactly. `mawk` and Python drew the vector above byte for byte the same.

A document's LIDs all open with the same eight characters, which name the
document. A GID is followed by decoding the header and finding the `k` whose
`doc` matches, by trying each entry of the toc or by a discrete logarithm in
a 31-bit group.

Each half is under 2^31, so its first hex digit runs from 0 to 7. A LID
carries 62 bits, not 64.

A document past 2^31 - 2 lines is split; the toc gives the rest a number.

This is not the generator Boost or the paper describes, and its LIDs cannot be
checked against theirs. The streams are the same; what is done with them is
not. The name says so.
