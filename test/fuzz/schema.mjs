// The schema cases of one fuzz case, for test/silt-fuzz.sh: schemas drawn
// from the seed for the value read from <dir>/value.json, written as
// <dir>/schemas.json, a list of {name, schema, value} as
// test/silt-validate.sh reads it. One schema is derived from the value,
// two are that schema loosened or broken in a place the seed picks, and
// two are drawn free of the value, so valid and invalid answers both come
// up. Every schema is one a validator accepts, in the keywords
// shell/silt/awk/validate.awk lists.
//
//   node schema.mjs 7 case  ->  case/schemas.json

import { readFileSync, writeFileSync } from "node:fs";
import { altered } from "./alterations.mjs";
import { derive } from "./derivedSchema.mjs";
import { drawerFrom } from "./draws.mjs";
import { free } from "./freeSchema.mjs";
import { jsonType, keysUnder, valuesUnder } from "./json.mjs";
import { holdsPlainTextAlone } from "./pattern.mjs";
import { KEYS, PIECES } from "./vocabulary.mjs";

const SCALARS = [null, true, false, 0, 1, -1, 1.5];

function main() {
  const [seed, dir] = usage(process.argv.slice(2));

  const value = JSON.parse(readFileSync(`${dir}/value.json`, "utf8"));
  const cases = casesOf(drawerFrom(seed), value, seed);

  writeFileSync(`${dir}/schemas.json`, `[\n${cases.map((one) => JSON.stringify(one)).join(",\n")}\n]\n`);
}

// The seed and the directory, or the usage and status 2.
function usage([seed, dir]) {
  if (!Number.isInteger(Number(seed)) || !dir) {
    process.stderr.write("usage: node schema.mjs <seed> <dir>\n");
    process.exit(2);
  }
  return [Number(seed), dir];
}

// What the generators know of the value: the keys and the scalars it is
// likely to hold, its own among them, and whether its text is plain.
function contextOf(value) {
  const scalars = valuesUnder(value).filter((member) => !["object", "array"].includes(jsonType(member)));
  return {
    keys: [...new Set([...keysUnder(value), ...KEYS])],
    scalars: [...scalars, ...SCALARS, ...PIECES],
    plain: holdsPlainTextAlone(value),
  };
}

// The cases of a value, each named for its seed and how it was drawn.
function casesOf(g, value, seed) {
  const context = contextOf(value);
  const derived = derive(g, value, context);
  const schemas = [
    ["derived", derived],
    ["altered", altered(g, derived, context)],
    ["altered again", altered(g, derived, context)],
    ["free", free(g, context)],
    ["free again", free(g, context)],
  ];

  return schemas.map(([name, schema]) => ({ name: `seed ${seed}, ${name}`, schema, value }));
}

main();
