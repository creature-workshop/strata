// Prints the random JSON value for a seed, for test/silt-fuzz.sh, as one
// compact line. test/fuzz/drawnValue.mjs draws the value.
//
//   node value.mjs 7  ->  {"k.d":null,"a":[1,"x y"]}

import { drawTree, render } from "./drawnValue.mjs";

function main() {
  const seed = usage(process.argv.slice(2));

  process.stdout.write(`${render(drawTree(seed))}\n`);
}

// Returns the seed, or prints the usage and exits with status 2.
function usage([seed]) {
  if (!Number.isInteger(Number(seed))) {
    process.stderr.write("usage: node value.mjs <seed>\n");
    process.exit(2);
  }
  return Number(seed);
}

main();
