# ADR.6: One grammar is written three ways: `.strh` to be read, `.strt` terse, and `.strata` terse and compressed

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/6
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1180
- Implementation: not started

## Context

A person reading a document and a store keeping a million of them want
different things from the same tree. Measured on 27,300 records of CI jobs,
two parts of a line carried nearly all of Strata's cost at rest. Random ids made a
compressed document ten times the size of the same data as JSON, and they can
be drawn again from a seed, byte for byte. The depth, key and type that open
every line were about half of its bytes, and writing them as a short code
brought the raw size under compact JSON's.

A second, binary format was weighed for the store and set aside
([ADR.2@opx](../000002-one-node-per-line/adr.md)). What the store needs is the
same lines with less in them.

## Decision

A document is written in one of three forms, and its file's ending says which.

```
.strh   5e71b83c0a2d9f46 1."allow_failure":bool=true
        7f2a90c4b5e8d163 2.0:str="landing"

.strt   1.@7:-4=1
        2.0:-3="landing"

.strata    the .strt text, compressed with zstd
```

- **`.strh`**, the human-readable form, writes every part of a line in full.
- **`.strt`**, the terse form, omits the LID and the space after it. It writes
  a string key as `@` and the key's code from the index
  ([ADR.5@opx](../000005-the-header/adr.md)), a type as its code
  ([ADR.3@opx](../000003-natural-primitives/adr.md)), and a `bool` as `1` or
  `0`. An index, the depth and every other value are written as `.strh` writes
  them.
- **`.strata`** is reserved for a terse document compressed with zstd. It is what
  a corpus keeps at rest.
- Translating between the forms MUST lose nothing. Given the header, a terse
  document becomes the `.strh` it was written from, LIDs included
  ([ADR.7@opx](../000007-ids-are-generator-state/adr.md)), byte for byte.
- A writer that meets a key the index lacks appends it before writing the
  line, where the header is open, and refuses the document where it is closed
  ([ADR.8@opx](../000008-strictness-lives-in-the-header/adr.md)).
- A reader MUST refuse a terse document that holds a code its header lacks.

## Consequences

The `@` keeps a key's code apart from an index on the line itself, so a
consumer that matches `1.@7:` never matches the eighth element of a list.

A header has no terse form, since its own keys are what a terse form would
need. Compressed or packed beside its corpus it stays `.strh` text.

A person cannot read a terse document without the header. The tool prints one
as `.strh`, and looks a key's code up by its text for a search. Read under
another corpus's header a terse document would not fail, it would name its
fields wrongly, so a tool takes a corpus's header from the corpus and from
nowhere else.

zstd is not in POSIX, so a shell script that reads an `.strata` calls the tool,
or a `zstd` beside it. The level is left to the tool.

