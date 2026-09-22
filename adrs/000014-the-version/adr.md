# ADR.14: A version names a manifest of features, a corpus declares the features it uses, and a tool reads it when it supports them all

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/17
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1224
- Implementation: not started

## Context

The default header carries the grammar's version
([ADR.5@opx](../000005-the-header/adr.md)), and nothing yet says how it is
numbered or what a tool does with it. A document has no preamble
([ADR.2@opx](../000002-one-node-per-line/adr.md)), so its corpus states it.

The grammar is append-only: a feature arrives in one grammar and is at
most retired in a later one, never changed. A version number alone answers
compatibility coarsely. A tool that dropped one retired feature would have
to refuse every corpus written before the retirement, whether the corpus
used that feature or not. Browsers learnt the same lesson and check for a
feature rather than a version.

## Decision

- A **feature** is anything the grammar defines that a corpus may use or
  not: a natural primitive, a generator, a part of the header, a rule. Each
  has a name. Grammar 1's are:

  ```
  null  map  list  str  bool  int  float  time-rfc3339-utc
  ecuyer1988-doc-line  closed  toc  digest  history  strata  keyless-line
  ```

- The **default header** is the manifest: for every feature, its name, the
  grammar it arrived in and, once retired, the grammar it left. A retired
  feature is never removed.
- The grammar's **version** is an integer from 1 naming the manifest as it
  stood: grammar n is the features alive at n. An ADR that adds or retires
  one names the number it introduces. These records are grammar 1.
- A corpus's fingerprint carries `version`, the grammar it was written
  under, and `uses`, the features it uses. A writer MUST list every
  feature it wrote and no other.
- A tool declares the features it supports. It MUST refuse a corpus that
  uses one it lacks, naming it, and MUST accept every other, whatever the
  version.
- A reader that meets a feature the corpus did not declare MUST refuse
  the document, naming the line.

## Consequences

Adding a feature breaks nothing: a corpus that does not use it reads as
before under every tool, and a tool that supports it reads every corpus that
does.

A tool retires a feature by dropping it from what it supports, at any
time and in any order. Only the corpora that use it are refused, and the
refusal names it. The manifest's retirement line is for people.

The version is documentation: which manifest, which records. The check never
reads it, so two tools at one version may support different sets, and the
sets are what get compared.

`uses` carries what a floor and a ceiling would, the newest arrival among
them and the earliest retirement, derived rather than stored.

The cost is a dozen names in every header, and a check that in `awk` is one
loop over them.

SQLite's read and write version pair and browser feature detection are the
two ancestors, and this takes the second.
