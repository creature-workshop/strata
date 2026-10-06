# strata

Dead simple high-performance data representation: a value written one node
per line, as a language an interpreter reads and a format data is stored in.

- `adrs/` holds the decisions, one page each (ADR.1@strata), from the line
  grammar (ADR.2) to SILT (ADR.32).
- `shell/silt/` holds SILT, structured inline live text: a document carried
  between shell functions without its id column, read and written in strict
  POSIX shell without starting a process, and translated to and from JSON,
  YAML and TOML in awk. It reports through `shell/.logs`, the shell-logs
  submodule, its one dependency at run time; `shell/.ops` vendors shellops
  for its tests, `shell/.golden` vendors shell-goldens, which its golden
  tests under `test/fixtures/silt/` run through, and `test/silt-fuzz.sh`
  fuzzes it against jq and yq.
- The reference of SILT, one page per module and an index, is rendered by
  shell-docs through the catalog's `docusaurus` package on every push and
  kept as
  [the pipeline's artifact](https://gitlab.creature-workshop.com/ksoft/strata/-/jobs/artifacts/main/browse/.ops/docs?job=ksoft%2Fdocusaurus%2Frender);
  after a push to main it goes to
  [docs.creature-workshop.com/strata](https://docs.creature-workshop.com/strata/)
  as the version `main`. Nothing tracks it.
- `.ops/config/` declares what the tests, the lint and the pipeline run
  (ADR.33): the tools, and under `git` in `tools.yaml` the shell libraries
  taken at a commit each, shell-scan, shell-tree, shell-docs and shell-lint.
  `ops install` derives `.ops/lock` from it, which is tracked. A pin moves
  in a merge request of its own.
