// The words the fuzz draws from, for test/fuzz/value.mjs and the schemas
// drawn beside it: a schema that names a key or a text the value is likely
// to hold meets the value far more often than one drawn blind.

// Every spelling a reader or a writer of JSON, YAML or TOML can get wrong.
export const PIECES = [
  "plain text", "yes", "null", "007", "1.5", "a: b", "- x", "tab\there",
  "line\nbreak", "two\n\nbreaks", "quote \" and \\ backslash", "café", "😀",
  "\u0001", "#hash", "~", "[flow]", "{a: 1}", "it's", "'single'", "0x1F", ".5",
  "1e5", "true", "2026-09-20T18:11:50Z", "on", "No", "trailing ", "",
];

// The keys a map is likely to hold, the awkward ones among them.
export const KEYS = [
  "a", "b", "key", "Key", "_", "with space", "k.d", "k[0]", "é", "☃", "007",
  "on", "test/a.bats", "a \"q\"", "z", "y", "x", "null", "1", "",
];
