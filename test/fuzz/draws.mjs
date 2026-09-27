// The draws the schema generators share, each taken from one drawer so a
// seed gives the same schemas every time. A drawer is fast-check's gen: a
// function that draws from an arbitrary it is handed.
//
//   const g = drawerFrom(7); whole(g, 1, 6)  ->  4

import fc from "fast-check";

// The drawer a seed gives.
export function drawerFrom(seed) {
  const [g] = fc.sample(fc.gen(), { seed, numRuns: 1 });
  return g;
}

// A whole number from min up to and with max.
export function whole(g, min, max) {
  return g(fc.integer, { min, max });
}

// One member of a list that holds one at least.
export function among(g, list) {
  return list[whole(g, 0, list.length - 1)];
}

// Whether a draw out of a hundred falls within the percent given.
export function chance(g, percent) {
  return whole(g, 1, 100) <= percent;
}

// Some members of a list, in the list's order, each kept on an even draw
// and no more than <most> of them.
export function several(g, list, most) {
  return list.filter(() => chance(g, 50)).slice(0, most);
}
