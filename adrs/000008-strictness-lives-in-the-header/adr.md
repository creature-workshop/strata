# ADR.8: Strictness lives in the header, so a language is a closed index and a store an open one

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/8
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1182
- Implementation: not started

## Context

Strata has two jobs. It is the form a program is compiled to, which an interpreter
walks and runs, and it is a format data is stored in. The first job wants a
small, fixed set of keys, since a key there is an instruction and an
interpreter has to know every one. The second wants any key a JSON document
may hold.

The first form answered with a strict grammar, keys held to lowercase words,
and the store then had to bend every other key into three lines. Two grammars,
one strict and one loose, were the next thought. They would have meant two
readers, two writers, and a question at every boundary.

## Decision

There is one grammar ([ADR.2@opx](../000002-one-node-per-line/adr.md)), and how
strict a corpus is belongs to its header
([ADR.5@opx](../000005-the-header/adr.md)), whose fingerprint MUST say whether
it is closed. The field has no default, so whoever makes a header chooses:

```
2f14432a4e41c033 1."closed":bool=true
```

- Under a **closed** header the index is a vocabulary. A reader MUST refuse a
  document that holds a key the index lacks, or a node whose type is not among
  those its key takes. A tool MUST NOT append to the index on its own.
- Under an **open** header a writer appends a key the first time it meets
  one, and adds to what the key takes a type it has not carried before.
- Closed binds the tools, not the language. A closed header is still revised
  as its language grows: its owner appends to it, through review, as a release
  of that language. It stays append-only, so an interpreter built for a later
  header runs every program compiled under an earlier one.
- An open header MAY be closed.

## Consequences

A language on Strata is a closed index and the meaning its interpreter gives each
key. Its instruction set is a document anyone can read, diff and review, in
the format it describes.

A language that wants its keys to be lowercase words names them so. Nothing
in the grammar stops a key from being any string
([ADR.4@opx](../000004-keys/adr.md)), and nothing has to.

A store starts with an empty open index and learns its keys from the data.
Once its shape settles it can be closed, and from then on a field that appears
unannounced is refused at the write, not found later in a report.

What a closed header checks is small on purpose: the key is known, and the
type is one it takes. Presence, values and how keys nest are the
interpreter's to check. Declaring how keys nest would be a later decision,
and the point where this header starts to become a schema language.
