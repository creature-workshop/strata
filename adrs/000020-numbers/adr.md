# ADR.20: A number's spelling is one of three patterns, and a translator keeps any other spelling as a map beside its value

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/23
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1226
- Implementation: not started

## Context

[ADR.3@opx](../000003-natural-primitives/adr.md) gives `int` a pattern and
`float` "any other JSON number, or inf, -inf, nan", and keeps a number's
text as written. "A JSON number" leaves its edges to whoever reads the
JSON grammar: `-0`, `1E5`, `+1`, `01`, `1.`, `.5`, and the case of `Inf`.
Two implementations that draw those edges differently accept different
documents.

YAML and TOML spell numbers JSON does not: `0x1F`, `0o17`, `1_000`,
`.inf`. And JSON itself has no `Infinity` or `NaN` at all (RFC 8259), so
a translator to JSON meets values it cannot write as numbers. Rewriting a
spelling loses it, and a natural primitive per source syntax would never
end.

## Decision

A number is written in one of these patterns and no other:

```
int     -?(0|[1-9][0-9]*)
float   -?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?   with a . or an e
        inf   -inf   nan
```

- `-0` matches `int` and is an `int`, its text kept. A writer that means
  negative zero writes `-0.0`.
- An exponent is `e` or `E`, kept as written. `inf`, `-inf` and `nan` are
  lower case and have no other spelling.
- A writer MUST refuse `+1`, `01`, `1.`, `.5`, `Infinity`, `NaN` and every
  other spelling, and a `float` binary64 cannot hold, as it refuses an
  `int` outside 64 bits.
- A translator that meets a number its target cannot carry, a spelling
  outside these patterns on the way in or `inf`, `-inf` and `nan` on the way
  out to JSON, writes a map in the number's place and loses nothing:

  ```
  0x1F from TOML     3."size":map
                     4."value":int=31              where the target holds it
                     4."spelling":str="0x1F"       as the source wrote it
                     4."format":str="toml"         the source's syntax
  inf to JSON        {"spelling":"inf","format":"strata"}
  ```

- A translator from JSON refuses `Infinity` and `NaN`, since they are not
  JSON.

## Consequences

The pattern is the specification. Two implementations accept and refuse the
same strings because they test the same regular expression, not because
they read RFC 8259 the same way.

Nothing is rewritten, so a round trip returns the spelling the source
wrote, and a consumer that wants arithmetic reads `value`. The map is the
shape ADR.3 gives a value richer than the primitives, and a header may name
it as a derived primitive ([ADR.5@opx](../000005-the-header/adr.md)) once
the first translator does.

No natural primitive is added per syntax, so there is no pairwise
equivalence to maintain between formats: the map carries the syntax's
name, and the table of names and spellings per translator is the hardening
ticket rather than this record.
