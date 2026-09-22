# ADR.11: A LID is drawn from the corpus's seeds, the document's number and the line's place, and from nothing else

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/14
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1235
- Implementation: not started

## Context

[ADR.7@opx](../000007-ids-are-generator-state/adr.md) makes a node's id the
state of a named generator, and starts every document's draw by mixing the
name of its unit into the seeds. A draw started from a name keeps two
documents apart only by odds, and a LID is meant to be unique across its
corpus by construction.

[ADR.10@opx](../000010-the-toc/adr.md) numbers the corpus's documents, which
gives a generator something better than a name to start from. An approved
record is not edited, so this record restates ADR.7 with the number in the
unit's place, and supersedes it.

## Decision

- A node's **local id**, its **LID**, is sixteen lowercase hex characters,
  and it MUST be unique across its corpus.
- The fingerprint holds two seeds, `doc-seed` and `line-seed`, each an `int`.
  They are the corpus's identity ([ADR.5@opx](../000005-the-header/adr.md)).
- A **global id**, a **GID**, is the two seeds as sixteen hex characters, a
  `.`, and the LID:

  ```
  doc-seed 1299709, line-seed 104729  ->  0013d4fd00019919.67e924b179c7e1f3
  ```

- The fingerprint's `rng` names a **generator**: the rule that gives line
  `i` of document `k` its LID from the two seeds, `k` and `i`, and from
  nothing else. The header's own lines are document 0's.
- A generator's LID is its state, never a value cut down from it. A step
  rearranges the states and merges no two.
- Every product a generator computes MUST stay under 2^53.
- A generator is defined by an ADR of its own, which gives its start, its
  step, how its state becomes sixteen characters, how many documents and
  lines it serves, and a test vector.
  [ADR.9@opx](../000009-ecuyer1988-doc-line/adr.md) defines
  `ecuyer1988-doc-line`, the default.
- A reader MUST know the generator a header names. A corpus whose generator
  it lacks is one it does not support, and it refuses the corpus
  ([ADR.14@opx](../000014-the-version/adr.md)) rather than read documents
  whose LIDs it cannot restore.

## Consequences

No name enters the draw, so renaming a document moves no id, and a document
draws the same LIDs packed as alone.

A LID names a place. A node that moves takes a new one, and so does every
node after an insert.

A GID names one datum among every corpus there is, and an owner who publishes
a corpus's seeds lets anyone find a datum in it. How a GID is followed to its
document is the generator's to say; the default makes it a lookup in the toc.

A new generator is a new ADR and a new name, and a name's meaning never
changes. `ecuyer1988-state`, the name ADR.7 reserved for a generator started
from a unit's name, was never defined and is not.
