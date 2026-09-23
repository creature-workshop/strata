# ADR.21: A document is at most 2^20 levels deep, and no implementation limits depth by recursion

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/24
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1227
- Implementation: not started

## Context

[ADR.2@opx](../000002-one-node-per-line/adr.md) reads a document with a
stack as deep as its tree and states no maximum. Left to each tool, one
refuses at 128 and another at a million, and the same document is valid to
one and not the other.

Compilers cap nesting to protect their own recursive parsers, not to say
anything about data:

```
C11 minimum 63   CPython 200   Lua 200   Clang and C++ 256   Chromium DOM 512
Jackson 1000     bison 10000   go/parser 100000 (a stack-exhaustion fix)
```

A Strata reader walks a document with a loop and an array indexed by depth,
so depth costs it memory, not stack, and every level is at least one line,
so that memory is never more than the document's own size. Measured: `mawk`
walked 2^20 levels in 0.18 s at 70 MB, and a recursive `awk` function dies
near 500 levels, since `mawk`'s evaluation stack is 1024 slots.

## Decision

- A node's depth is at most 2^20 - 1, so a document is at most 2^20 levels
  deep counting depth 0.
- A reader MUST refuse a line whose depth is greater, naming the line.
- A writer MUST refuse a value that would nest deeper, and a translator
  MUST refuse a source document that does, naming where.
- A reader or writer MUST NOT limit depth by recursion. A walk over a
  document's depth keeps its own stack, so the bound above is the only
  bound an implementation has.

## Consequences

Every implementation refuses the same document at the same line, and
refuses no other. Depth is never a tool-specific difference.

The bound is far above every language's own cap, so no program tree a real
compiler produced is refused, and far above data, which nests under ten.
It is sized for memory: at the bound a document is a million lines and a
reader holds a million small entries, which `awk` did in 70 MB.

A hostile document costs a reader what it costs the disk, and nothing more.
There is no stack to exhaust.

What a consumer's own parser tolerates once a document is translated is the
translator's concern: .NET's JSON reader stops at 64 by default and
serde_json at 128, both configurable, and the translators' hardening ticket
carries that.

The bound is a grammar constant, so raising it is a later grammar and the
version carries it ([ADR.14@opx](../000014-the-version/adr.md)).
