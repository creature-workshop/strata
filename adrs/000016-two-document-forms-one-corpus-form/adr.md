# ADR.16: One grammar has two document forms, `.opxh` and `.opxt`, and one corpus form, `.opx`

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/19
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1234
- Implementation: not started

## Context

[ADR.6@opx](../000006-three-forms/adr.md) gave one grammar three spellings of
a document, and made `.opx` a terse document compressed alone. Such a file
travels without the header that names its fields, and read under another
corpus's header it does not fail, it misnames every field.

[ADR.15@opx](../000015-the-pack/adr.md) makes `.opx` a corpus at rest, header
included. That leaves no compressed form of a lone document, and none is
wanted: a document alone is a corpus of one. An approved record is not
edited, so this record restates ADR.6 and supersedes it.

## Decision

A document is written in one of two forms, a corpus at rest in one, and a
file's ending says which.

```
.opxh   5e71b83c0a2d9f46 1."allow_failure":bool=true
        7f2a90c4b5e8d163 2.0:str="landing"

.opxt   1.@7:-4=1
        2.0:-3="landing"

.opx    the corpus: its header and its documents, as ADR.15 lays them out
```

- **`.opxh`**, the human-readable form, writes every part of a line in full.
- **`.opxt`**, the terse form, omits the LID and the space after it. It
  writes a string key as `@` and the key's code from the index
  ([ADR.5@opx](../000005-the-header/adr.md)), a type as its code
  ([ADR.3@opx](../000003-natural-primitives/adr.md)), and a `bool` as `1` or
  `0`. An index, the depth, a keyless line's empty key and every other value
  are written as `.opxh` writes them.
- Unpacked, a corpus is a directory: its header in a file ending
  `.opxh.head`, and each document at its toc path with a document ending.
- A header has no terse form, since its own keys are what a terse form would
  need. Inside a `.opx` it is `.opxh` text.
- Translating between the forms MUST lose nothing. Given the header, a terse
  document becomes the `.opxh` it was written from, LIDs included
  ([ADR.11@opx](../000011-lids-from-number-and-place/adr.md)), byte for byte.
- A writer that meets a key the index lacks appends it before writing the
  line where the header is open, and refuses the document where it is closed
  ([ADR.8@opx](../000008-strictness-lives-in-the-header/adr.md)).
- A reader MUST refuse a terse document that holds a code its header lacks.

## Consequences

The `@` keeps a key's code apart from an index on the line itself, so a
consumer that matches `1.@7:` never matches the eighth element of a list.

A person cannot read a terse document without its header. The tool prints
one as `.opxh`, and looks a key's code up by its text for a search. A tool
takes a corpus's header from the corpus and from nowhere else.

Nothing compressed ever leaves its header behind. What ADR.6 warned of, a
terse document read under the wrong header, cannot happen to a `.opx`.

zstd is not in POSIX, so a shell script that reads a `.opx` calls the tool,
or a `zstd` beside it.
