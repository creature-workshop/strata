# ADR.2: An OPX document is a value written one node per line

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/2
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1176
- Implementation: not started

## Context

OPX stores a value as text: a tree, a list of records, or one primitive. Its
first form, written in shellops, put a node on a line as
`<id> <depth>.<role>:<type>.<value>`. One dot parted the depth from the role
and another the type from the value.

Text lines were measured against JSON on 27,300 records of CI jobs. Compressed,
the two were within 2 percent, and a sixty-line C reader read OPX as fast as
the fastest JSON parsers read JSON. What lines buy is that a shell, `grep` and
one `awk` rule read a document with no parser.

A binary form was set aside: raw integers hold the newline byte, so it must be
framed by lengths, and no line tool reads it.

## Decision

A document is UTF-8 text, and every line of it is one node:

```
<lid> <depth>.<key>:<type>
<lid> <depth>.<key>:<type>=<value>
```

- The four marks of a node are a space, `.`, `:` and `=`. Each appears once,
  in that order, before the value begins.
- A line with `=` is a leaf. A line without one has no value: a collection,
  whose children are the lines that follow it one level deeper, or a null.
- `<depth>` is a decimal number. A node's parent is the nearest line above it
  at one less depth, and a line MUST NOT sit more than one level deeper than
  the line above it.
- The lines at depth 0 are the document's top level, and they are the members
  of a map or the elements of a list, as their keys say
  ([ADR.4@opx](../000004-keys/adr.md)). A document of one primitive is one
  line. A list of records reads across to JSON Lines, and appending a record
  appends lines.

  ```
  3c3064613c9a4244 0.0:map
  540218b978365309 1."name":str="build"
  5fd653d71b97e59c 0.1:map
  4e8b6ad50c9e74d4 1."name":str="test"
  ```

- A document holds nothing but nodes: no preamble, no blank line, no comment.
  Its line count is its node count. What a document needs from outside
  itself, it finds in its corpus's header
  ([ADR.5@opx](../000005-the-header/adr.md)).
- A reader MUST refuse a line that does not fit, naming its line number.

[ADR.7@opx](../000007-ids-are-generator-state/adr.md) says what a LID is,
[ADR.3@opx](../000003-natural-primitives/adr.md) a type and a value, and
[ADR.6@opx](../000006-three-forms/adr.md) gives the line a shorter spelling.

## Consequences

A reader splits a line one way, left to right. A consumer that wants one field
matches a prefix and takes what follows the `=`.

A document is read in one pass with a stack as deep as the tree. Nothing marks
its end, so one cut at a line boundary reads as a shorter document. Catching
that is left to what carries it: a compressor's frame, or a write under a
temporary name.

The first form's documents are compiled output, so nothing stored is migrated.
