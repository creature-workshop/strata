# ADR.3: Every node carries a type, and OPX's eight natural primitives are the ones every corpus shares

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/3
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1177
- Implementation: not started

## Context

The first form of OPX typed only its leaves. Whether a node with children was
a list or a map was guessed from them, which took a reserved role and three
made-up leaves for a null, an empty list and an empty map.

Across the common storage formats (JSON, YAML, TOML, MessagePack, CBOR, Avro,
Protobuf, Parquet) the types every typed one shares are a boolean, a 64-bit
integer, a float, a string, a list and a map. A null and a timestamp are one
step out, and a format that lacks one cannot round-trip a format that has it.

## Decision

Every node MUST carry a type, a collection included. Eight are OPX's **natural
primitives**: the language defines them, the default header carries them
([ADR.5@opx](../000005-the-header/adr.md)), and no corpus declares them.

```
 0 null               no value
-1 map                no value; its children are its members, a key held once
-2 list               no value; its children are its elements, in order
-3 str                a JSON string literal, quotes and escapes included
-4 bool               true or false
-5 int                -?(0|[1-9][0-9]*), a signed 64-bit integer
-6 float              any other JSON number, or inf, -inf, nan; IEEE binary64
-7 time-rfc3339-utc   an instant, 2026-09-20T18:11:50.946Z
```

- They run in order of how specific a thing each is, from nothing, through
  the collections and free text, to the narrowest. A later natural primitive
  SHOULD keep to that order where it can.
- A natural primitive's code is 0 or below, and a later one takes the next
  code down. A **derived primitive**, a type a corpus's header defines, takes a
  code from 1 up. The two never meet, and neither commits to a width.
- An `int` and a `float` mean the same on every device: 64 bits each. A writer
  MUST refuse a number outside them.
- A number keeps the text its source wrote. A reader MUST NOT round or
  reformat it when copying it.
- A `str` is a JSON string literal, so a translator from or to JSON copies it
  untouched.
- A `time-rfc3339-utc` has a capital `T` and `Z` and no offset. A writer
  converts an offset to UTC on the way in. The name says the format, so
  another format for time takes another name.
- An empty map or list is its one line with no children.
- A value richer than these is a map of them, which a header names as a
  derived primitive. A code is never reused.

## Consequences

`{}` and `[]` are different documents, and so are `[1]` and `{"0":1}`.

`awk` holds an integer exactly only to 2^53. That limits what an `awk` program
may compute, not what it may carry: a value is text, copied as text.

A time reads back equal in value, not always in bytes: an offset is gone once
converted. A JSON string is a time only when the header says its key takes
one.

Bytes have no type yet, nor an integer past 64 bits.

A program's steps are a list, and a list may hold the same kind of step twice.
Only a map refuses a repeat.
