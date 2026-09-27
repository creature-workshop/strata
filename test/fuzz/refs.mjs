// The references a drawn schema holds to a schema under its own $defs,
// the names among them that a JSON pointer spells another way.
//
//   refTo("a/b")  ->  "#/$defs/a~1b"

// The names a schema under $defs takes.
export const REF_NAMES = ["n", "with space", "a/b", "a~b", "é", ""];

// A name as a JSON pointer's token spells it.
function tokenOf(name) {
  return name.replaceAll("~", "~0").replaceAll("/", "~1");
}

// The reference to the schema a name holds under $defs.
export function refTo(name) {
  return `#/$defs/${tokenOf(name)}`;
}
