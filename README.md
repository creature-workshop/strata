# strata

Dead simple high-performance data representation: a value written one node
per line, as a language an interpreter reads and a format data is stored in.

- `adrs/` holds the decisions, one page each (ADR.1@strata), from the line
  grammar (ADR.2) to the name (ADR.31).
- `shell/silt/` holds SILT, structured inline live text: a document carried
  between shell functions without its id column, read in strict POSIX shell
  without starting a process. `shell/.ops` vendors shellops for its tests.
