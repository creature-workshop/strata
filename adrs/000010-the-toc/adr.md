# ADR.10: A corpus's header lists its documents in a toc, and a document's number is its place there

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/13
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1191
- Implementation: not started

## Context

A corpus's header ([ADR.5@strata](../000005-the-header/adr.md)) knows the
corpus's seeds and its keys, and nothing of its documents. A document is
addressed by the name of its unit, so a LID drawn from that name keeps two
documents apart only by odds, and a corpus packed into one file has no order
to store its documents in and, since nothing marks a document's end
([ADR.2@strata](../000002-one-node-per-line/adr.md)), no way to find where one
stops and the next begins.

An archive's table of contents answers all three at once: it numbers the
members, fixes their order, and says how long each is.

## Decision

The header holds a third part after the index, the **toc**: a list of the
corpus's documents.

```
312d254d2ba9305a 0."toc":list
7e903972094e5e40 1.0:map
732649383ce8921e 2."path":str="jobs/2026-09"
6a771edc18235a23 2."lines":int=41207
```

- A document's **number** is its place in the toc counted from 1. The header
  is document 0 and has no entry.
- `path` is where the document stands under the corpus's root: segments
  joined by `/`, none of them `.` or `..`, and no file ending, since the
  ending says the form ([ADR.6@strata](../000006-three-forms/adr.md)). Unpacked,
  the document is the file `<root>/<path>.<ending>`. No two entries share a
  path.
- `lines` is the document's line count, which is its node count, and it is
  an invariant: a reader MUST refuse a document whose count differs from its
  entry, naming both.
- The toc is append-only. An entry MUST NOT be removed or moved, so a number
  is never given twice. `path` MAY change, and `lines` changes with every
  append.
- A document MUST have its entry before its first line is written.

## Consequences

A number is a document's identity in its corpus, and a name is not. Renaming
a file changes its entry's text and nothing else, and
[ADR.11@strata](../000011-lids-from-number-and-place/adr.md) draws LIDs from the
number, so no id moves with it.

Every append to any document rewrites the header, under the one writer a
corpus already has. That is the cost.

Reading a pack as one stream of lines, `lines` says where each document
ends; read alone, a document that is shorter than its entry is truncated
and one that is longer is stale, and either is refused before it is trusted.

A deleted document keeps its number and its entry. What the tool does with an
entry whose file is gone is the tool's to say.

How a corpus is packed into one file, in toc order, is
[ADR.15@strata](../000015-the-pack/adr.md).
