# ADR.32: SILT is a `.strh` document carried inline without its id column, and writing it into a corpus draws the ids

- Status: approved
- Date: 2026-09-26
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/61
- Argued from: https://app.notion.com/p/3e764bb41da6811cb429f6e67320f7fd
- Implementation: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/58

## Context

A value passed between shell functions needs a written form, and neither
document form fits one in flight. A `.strh` line opens with a LID drawn
from the corpus's seeds, the document's number and the line's place
([ADR.11@strata](../000011-lids-from-number-and-place/adr.md)); a value
built in a shell has none of the three. A `.strt` line writes keys and
types as codes from a header
([ADR.16@strata](../000016-two-document-forms-one-corpus-form/adr.md)), and
a variable carries no header. The rest of a line a shell reads with no
parser or process.

## Decision

**SILT**, structured inline live text, is a Strata document without its id
column: each line a `.strh` line
([ADR.2@strata](../000002-one-node-per-line/adr.md)) with the LID and the
space after it removed, nothing else changed.

```
.strh   5e71b83c0a2d9f46 0."runner":str="bats"
        2d8c15f07a3e9b64 0."tests":map
        7f2a90c4b5e8d163 1."test/a.bats":map
        0b6d4f92e1a7c358 2."reads":list
        9a1c44e0d27b5f13 3.0:str="lib/a.sh"

SILT    0."runner":str="bats"
        0."tests":map
        1."test/a.bats":map
        2."reads":list
        3.0:str="lib/a.sh"
```

- A line is `<depth>.<key>:<type>` for a collection or a null, and
  `<depth>.<key>:<type>=<value>` for a leaf: root at depth 0, a JSON string
  key under a map and an index under a list
  ([ADR.4@strata](../000004-keys/adr.md)), a type by name
  ([ADR.3@strata](../000003-natural-primitives/adr.md)), one keyless line
  for a scalar or an empty collection
  ([ADR.12@strata](../000012-keyless-line/adr.md)). Every other rule holds.
- No header, no ids, no version: a document alone is complete.
- SILT is a value in flight, never at rest: no corpus holds one. A file
  holding one, a fixture or a spill, ends `.silt`. In a variable it has no
  final LF; on a stream it ends in one
  ([ADR.19@strata](../000019-text/adr.md)).
- **Writing** a document into a corpus gives it a toc number
  ([ADR.10@strata](../000010-the-toc/adr.md)), draws each line's LID from
  the seeds, the number and the line's place, and puts it in front.
  **Reading** a `.strh` into SILT removes it; reading a `.strt` is ADR.16's
  translation to `.strh` with the ids undrawn. Nothing else changes, so a
  document written back to its number unchanged draws the LIDs it had.
- The translation is always explicit. A `.strh` reader MUST refuse a line
  without a LID, and a SILT reader MUST refuse one that opens with a LID or
  carries a code, naming the line. The caller names the form, by the file's
  ending or the verb's name; no tool guesses.

## Consequences

`.strh` is SILT with a column in front: each translation is one field per
line.

A value in flight has no address. Provenance is recorded where it is
written, in the history ([ADR.18@strata](../000018-the-history/adr.md)),
and a document read whole has its LIDs back from its seeds and number.

A `.strh` missing its column is broken, and a SILT carrying one is not
SILT. Each is refused, so no document loses or invents ids unnoticed.

The draw is thirty-one multiplications under 2^47
([ADR.9@strata](../000009-ecuyer1988-doc-line/adr.md)), exact in dash's and
bash's arithmetic, so a shell writes a `.strh` without a process.

SILT is no feature of the manifest
([ADR.14@strata](../000014-the-version/adr.md)): a corpus never uses it.
