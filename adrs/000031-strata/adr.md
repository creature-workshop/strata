# ADR.31: The language is Strata, its files end `.strata`, `.strt` and `.strh`, and every record is re-spelled by this rename and changed in nothing else

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/36
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1243
- Implementation: not started

## Context

The language began as OPX, a placeholder from the first day of rulings
([ADR.1@opx](../000001-one-page-adrs/adr.md)), and the naming lane weighed
datum, atom, kerr and keep against it. None said what the thing is.

[ADR.15@opx](../000015-the-pack/adr.md) named the unit a stratum, after
geology: laid down in order, never reworked, the newest on top, each
carrying the record of its own forming, and the history of a place read
down through them. Every later record leaned on the word, and the unit
turned out to name the whole. The obvious short ending, `.str`, is taken in
the wild and reads as "string" first.

## Decision

- The language is **Strata**. Written as a name it is capitalised; written
  in lower case, strata are the layers of a file, as
  [ADR.15@opx](../000015-the-pack/adr.md) has them.
- Its files end as follows, and the header file follows the readable form.

  ```
  .strata      a corpus at rest, one or more strata          was .opx
  .strt        a document, terse                              was .opxt
  .strh        a document, readable                           was .opxh
  .strh.head   the header, unpacked                           was .opxh.head
  ```

- `.str` is an alias of `.strata`. A reader MUST accept a corpus under
  either ending; a writer MUST write `.strata`, so two implementations
  write the same name.
- Where a record writes the language's own name as a value, it is `strata`:
  the `format` of a native spelling
  ([ADR.20@opx](../000020-numbers/adr.md)) and a run's name.
- Every record is re-spelled by this rename and changed in nothing else:
  numbers, dates, decisions and citations stand. A citation still reads
  `ADR.<n>@opx`, since the repository keeps its path until that is ruled.
- No reader accepts the old endings. None exists yet, so nothing was
  written under them.

## Consequences

One word names the language, its file and its unit, so a reader who has
learned any one of them has the others, and the name says the model: a
corpus is its strata, and the history is the log read from them.

The records read as if the name had always been Strata. The rename's own
commit is where the old spelling survives, and git carries it.

The repository, the Linear project and the citation form still say opx.
Renaming those is a separate act, with its own blast radius in clones,
links and the citation lint, and this record does not take it.
