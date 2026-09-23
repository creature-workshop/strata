# ADR.7: A node's local id is the state of a named generator, and the corpus's seeds in front make it global

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/7
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1181
- Implementation: not started

## Context

An id names a node so that anything outside the document can point at it. The
first form drew five characters at random from a seed and, when two collided,
drew again. Such ids can be cut from a stored document and drawn again byte
for byte, which matters because random text does not compress.

To restore ids drawn that way a reader must repeat every redraw, so it must
remember every id it has seen. And the draw has to give the same bytes in
every language, `awk` among them, whose numbers are exact only up to 2^53.

## Decision

- A node's **local id**, its **LID**, is sixteen lowercase hex characters. It
  is what a line carries, and it is meant to be unique across its corpus: two
  documents of a corpus holding the same LID is a flaw.
- A **global id**, a **GID**, is the corpus's two seeds as sixteen hex
  characters, a `.`, and the LID:

  ```
  seeds 104729 and 1299709  ->  000199190013d4fd.1b35966b49da4467
  ```

- The fingerprint's `rng` ([ADR.5@strata](../000005-the-header/adr.md)) names a
  **generator**: the rule that gives the nth node of a document its LID from
  the seeds, the document's unit and n, and from nothing else.
- A generator's LID is its state, never a value cut down from it. A step
  rearranges the states and merges no two, so within its period no LID comes
  round again.
- Every product a generator computes MUST stay under 2^53.
- A generator is defined by an ADR of its own, which gives its step, how its
  state becomes sixteen characters, how many nodes it serves, and a test
  vector. [ADR.9@strata](../000009-ecuyer1988-state/adr.md) defines
  `ecuyer1988-state`, the default.
- Every generator starts a document from the seeds and the unit through one
  function, a byte of the unit's UTF-8 text at a time:

  ```
  mix(seed, unit):  h = seed;  for each byte b:  h = (h * 31 + b) mod 2147483647
  ```

- A reader that does not know a header's `rng` MUST still read its documents,
  and MUST refuse only to restore their LIDs.

## Consequences

No two nodes of a document share a LID, by construction. How a generator
keeps the documents of a corpus apart, its own ADR says. The grammar needs no
rule for a collision, and a reader restores LIDs in a stream, remembering
none.

A GID names one datum among every corpus there is. An owner who publishes a
corpus's seeds lets anyone find a datum in it by its GID. A GID does not say
which unit holds the datum, so finding it is a search for now.

A LID names a place. A node that moves takes a new one, and so does every node
after an insert.

A new generator is a new ADR and a new name, and a name's meaning never
changes.
