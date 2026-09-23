# ADR.23: A time has one spelling, nine fraction digits and Z

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/26
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1229
- Implementation: not started

## Context

[ADR.3@strata](../000003-natural-primitives/adr.md) makes `time-rfc3339-utc`
an RFC 3339 instant in UTC with a capital `T` and `Z`, and has a writer
convert an offset to UTC on the way in. RFC 3339 leaves the fraction's
width free, so `18:11:50Z`, `18:11:50.9Z` and `18:11:50.900Z` are one
instant spelled three ways, and since `.` sorts before `Z`, the text order
of those three is not their time order.

A writer already rewrites a time once, to turn an offset into `Z`. Fixing
the width is the same act, and it leaves an instant one spelling.

## Decision

A `time-rfc3339-utc` value is written exactly as

```
YYYY-MM-DDTHH:MM:SS.nnnnnnnnnZ        2026-09-22T06:10:04.000000000Z
```

- The fraction is exactly nine digits. A writer pads a shorter fraction
  with zeros on the right, and one with no fraction with nine zeros.
- A writer MUST refuse a fraction longer than nine digits, as it refuses
  an `int` outside 64 bits. Nothing is rounded.
- A reader MUST refuse any other spelling of a time, naming the line.
- The date and the clock are as RFC 3339 has them: a four-digit year, and
  `:60` where a leap second is one.

## Consequences

One instant has one spelling, in every corpus, from every writer. Two
implementations write the same thirty bytes for the same instant, and a
line that holds a time can be compared as text: within a key, across
keys, and across corpora, text order is time order.

A source that gave milliseconds is written with six trailing zeros, which
claims a precision it did not have. That is the cost, and it is the same
cost a `float` pays when `1.5` is stored as binary64.

Thirty bytes a time, six more than milliseconds. Trailing zeros compress to
nothing.

`awk` compares two times with `<` on the strings, needing no clock library,
which is the reason to fix the width rather than merely to canonicalise
it.

A translator to JSON writes the same thirty characters, and a translator
from JSON reads a string as a time only where the header says the key
takes one ([ADR.5@strata](../000005-the-header/adr.md)).
