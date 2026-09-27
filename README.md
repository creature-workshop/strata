# strata

Dead simple high-performance data representation: a value written one node
per line, as a language an interpreter reads and a format data is stored in.

- `adrs/` holds the decisions, one page each (ADR.1@strata), from the line
  grammar (ADR.2) to SILT (ADR.32).
- `shell/silt/` holds SILT, structured inline live text: a document carried
  between shell functions without its id column, read and written in strict
  POSIX shell without starting a process, and translated to and from JSON,
  YAML and TOML in awk. It reports through `shell/.logs`,
  the shell-logs submodule, its one dependency at run time; `shell/.ops`
  vendors shellops for its tests.
