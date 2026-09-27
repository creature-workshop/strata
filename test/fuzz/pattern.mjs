// The patterns a drawn schema holds. silt__validate matches a pattern as
// an extended regular expression and the jq validator as Oniguruma does,
// and the two agree by design over what an extended regular expression
// spells, with \d, \w and \s, read against plain text: printable ASCII and
// the tab. So a pattern is drawn from that spelling alone, with no "(?",
// no word boundary and no back reference, and a schema holds one only when
// every text and every key of the value it is checked against is plain.
//
//   patternOf(g, "v 12")  ->  "^[a-z]+ \\d+$"

import { among, chance, whole } from "./draws.mjs";
import { keysUnder, valuesUnder } from "./json.mjs";

// Patterns a text of the fuzz's vocabulary is likely to meet either way.
const COMMON = [
  "^\\d+$", "^[a-z]+$", "\\s", "^\\w+( \\w+)*$", "^[a-z ]+$", "\\d\\.\\d",
  "^\\S+$", "^\\D*$", "^[A-Za-z0-9_.-]+$", "^.{0,4}$", "^(yes|no|on)$",
  "^[^a-z]", "^\\W", "^[\\w.]+$", "^[\\d-]+T", "^a{1,2}$", "^[0-9a-f]{2,}$",
  "e$", "^$", "^[\\s\\d]*$",
];

const ATOMS = [
  "a", "e", "t", "x", "0", "1", " ", "-", "_", ":", "\\d", "\\w", "\\s",
  "\\D", "\\W", "\\S", ".", "[a-z]", "[0-9a-f]", "[\\w.]", "[^a-z]", "[\\d-]",
  "\\.", "(ab)", "(a|b)", "(\\d|x)",
];

const REPETITIONS = ["", "", "", "+", "*", "?", "{2}", "{1,}", "{1,3}"];

// The characters an extended regular expression reads as more than
// themselves.
const SPECIAL = /[.^$*+?()[\]{}|\\]/g;

// Whether a text is plain: printable ASCII and the tab, and nothing else.
export function isPlain(text) {
  return /^[\t\x20-\x7e]*$/.test(text);
}

// Whether every text and every key under a value is plain.
export function holdsPlainTextAlone(value) {
  const texts = valuesUnder(value).filter((member) => typeof member === "string");
  return [...texts, ...keysUnder(value)].every(isPlain);
}

// One to three atoms, each repeated as drawn.
function sequence(g) {
  const terms = Array.from({ length: whole(g, 1, 3) }, () => among(g, ATOMS) + among(g, REPETITIONS));
  return terms.join("");
}

// A pattern written from the atoms, anchored at either end as drawn.
function written(g) {
  const body = chance(g, 20) ? `(${sequence(g)}|${sequence(g)})` : sequence(g);
  return `${chance(g, 50) ? "^" : ""}${body}${chance(g, 50) ? "$" : ""}`;
}

// A pattern drawn free of any text.
export function pattern(g) {
  return chance(g, 50) ? among(g, COMMON) : written(g);
}

// A run of digits or of lower-case letters as the class that holds it, or
// as it is written, and any other text with its special characters escaped.
function generalized(g, run) {
  if (/^\d+$/.test(run) && chance(g, 60)) {
    return "\\d+";
  }
  if (/^[a-z]+$/.test(run) && chance(g, 60)) {
    return "[a-z]+";
  }
  return run.replace(SPECIAL, "\\$&");
}

// A pattern the plain text given matches from end to end.
export function patternOf(g, text) {
  const runs = text.match(/\d+|[a-z]+|[^\da-z]+/g) ?? [];
  return `^${runs.map((run) => generalized(g, run)).join("")}$`;
}
