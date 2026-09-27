# ADR.33: strata takes shell-logs at run time and nothing else, and takes shellops and the catalog only to check itself, each at a pin

- Status: approved
- Date: 2026-09-27
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/73
- Argued from: https://linear.app/grand-cluster-city/issue/STRATA-182
- Implementation: not started

## Context

Strata is the foundation: shellops is to run its structs on SILT
([ADR.32@strata](../000032-silt/adr.md)), so shellops depends on strata at
run time. strata in turn takes three things from outside.

```
shell/.logs      shell-logs, which SILT reports a refusal through
shell/.ops       shellops: the lint, the bats libraries, a test's oracle,
                 the Linear client a fuzz report files through, the installer
.gitlab-ci.yml   seven members of the creatures catalog: governance, labels,
                 the hat, the lints and the test job
```

Two repositories that depend on each other can stop each other. A break in
shellops that reached the code a caller of SILT runs would break shellops'
own foundation, and neither could be mended first.

## Decision

A dependency is **run-time** when the code a caller of strata runs reads
it, and **dev-time** when only a test, a lint or a pipeline does.

- At run time strata takes shell-logs and nothing else. Nothing under
  `shell/silt/` MUST read `shell/.ops`, `SHELLOPS_DIR` or any file of
  shellops, and the same holds for every later implementation.
- A run-time dependency MUST itself take nothing at run time from shellops
  or the catalog. Another one is added by an ADR that supersedes this
  line.
- At dev time strata MAY take from shellops what checks it or reports on
  it: a lint, a test library, an oracle a test holds an answer to, a client
  a report is filed through, an installer of tools.
- It MAY include a catalog member that governs a merge request or runs a
  lint or a test. It MUST NOT include one that builds, releases or
  publishes what a caller runs, until an ADR says how strata is released.
- Every dependency is taken at a pin: a submodule at a commit, a catalog
  member at an exact version, never a branch or a range. A pin moves in a
  merge request of its own, whose pipeline is the check that strata still
  passes under it.
- strata carries its own tests: the cases, their expected answers and the
  scripts that run them live in `ksoft/strata`. An oracle from shellops is
  a second opinion on an answer, never the only record of it.

## Consequences

No cycle runs at run time. shellops reads strata, strata reads shell-logs,
and shell-logs reads neither.

The cycle at dev time is held open by the pins. A broken shellops or
catalog stops strata only when strata moves a pin onto it, and that merge
request fails where it can be seen and left unmerged.

A lint rule or a catalog fix reaches strata a pin later than it lands. The
house lint already runs ahead of the vendored pin, through a catalog member
at its own version, so the two pins move apart and each is its own merge
request.

`test/silt-validate.sh` holds `silt__validate` to shellops' jq validator.
Once shellops validates through strata that oracle is strata itself, so
the cases' expected answers are written into strata before then.

A Rust implementation's crates are a dependency of another kind, and take
an ADR of their own.
