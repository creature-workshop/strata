# ADR.1: strata records each decision as a one-page ADR, in the global form

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/1
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1175
- Implementation: not started

## Context

Strata begins as a day of design rulings: what a line holds, which types a node
takes, what a header is for, how an id is drawn. A ruling made in conversation
is lost to the next reader unless it is written where the language lives, and
a language outlives every tool that reads it, so its decisions have to be
findable one at a time.

The organisation already has a form for this.
[ADR.1@global](https://gitlab.creature-workshop.com/ksoft/global-adrs/-/blob/main/adrs/0001-global-adrs/adr.md)
makes a shared decision one page, keeps the argument elsewhere, and asks every
repository that follows it to say so in an ADR of its own.

## Decision

strata adopts the form of
[ADR.1@global](https://gitlab.creature-workshop.com/ksoft/global-adrs/-/blob/main/adrs/0001-global-adrs/adr.md)
for its own decisions.

- An ADR MUST hold one decision: context, decision, consequences.
- Its prose MUST fit one page: at most 450 words from the Context heading to
  the end. Fenced examples and figures are free.
- It MUST NOT carry the research, the alternatives at length, or the plan. The
  argument is a design document or a ticket, linked from the header. The plan
  is tickets.
- An ADR lives at `adrs/<n>-<slug>/adr.md`, the number padded to six digits,
  beside a `figures/` directory when it has figures.
- ADRs are numbered from 1, each taking the next free number when its merge
  request opens.
- An ADR is cited as a link whose text is `ADR.<n>@strata`, with no leading
  zeros:

  ```
  [ADR.2@strata](../000002-one-node-per-line/adr.md)
  ```

- The merge request is the discussion. An ADR is written with
  `Status: approved`, since the merge that lands it is the approval and a
  record that was not approved never reaches the main branch. Closing the
  merge request with a reason is rejection.
- An approved ADR MUST NOT be edited, except for two header lines: Status,
  which names the ADR that superseded it, and Implementation, which points at
  the merge request that builds it.

## Consequences

A decision is small enough to read in a merge request diff. A large design
becomes several ADRs that cite each other, and a shared term gets an ADR of
its own.

Each ADR arrives in a merge request of its own, so one can be argued, changed
or rejected without holding up the others. ADRs ruled together cite each
other, and a citation resolves once both have merged.

The form is checked, not remembered. `lint.json` names the folder and the
one-page form, and shellops' lint holds every record to it in the merge
request's pipeline: the title, the header, the section order, the citations,
the page, and a number no other record carries.
