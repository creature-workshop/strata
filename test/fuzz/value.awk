# A random JSON value from a seed, for test/silt-fuzz.sh: one compact line
# with every map's keys in canonical order, so reading it into SILT and
# writing it back must give the same bytes. The value is built over an
# explicit stack of open collections, and drawn by a Lehmer generator of
# this file's own, since no two awks agree on rand(). It keeps to what jq
# and yq spell the same way: ints within 2^53, decimals with a digit after
# the point, no exponent, no -0, and keys inside the Basic Multilingual
# Plane; the awkward cases live in the strings and the keys.
#
#   awk -v seed=7 -f value.awk  ->  {"a":[1,"x y"],"k.d":null}

# The next draw, from 0 up to but not 1: Lehmer's generator, whose products
# stay exact in awk's numbers.
function draw() {
  STATE = (STATE * 48271) % 2147483647
  return (STATE - 1) / 2147483646
}

# A whole number from 0 up to but not n.
function pick(n) {
  return int(draw() * n)
}

# Whether a draw falls under the percentage.
function chance(percent) {
  return draw() * 100 < percent
}

# Moves the generator past its first draws, which stay small for a small
# seed and would make every low seed a scalar.
function warm_up(__i) {
  for (__i = 0; __i < 16; __i++) {
    draw()
  }
}

# One character as a JSON string literal spells it.
function escape_char(c) {
  if (c == "\"") {
    return "\\\""
  }
  if (c == "\\") {
    return "\\\\"
  }
  if (c == "\n") {
    return "\\n"
  }
  if (c == "\t") {
    return "\\t"
  }
  if (c == "\001") {
    return "\\u0001"
  }

  return c
}

# Text as a JSON string literal.
function literal(text, __out, __i) {
  __out = ""

  for (__i = 1; __i <= length(text); __i++) {
    __out = __out escape_char(substr(text, __i, 1))
  }

  return "\"" __out "\""
}

# A random string: one to three pieces from the pool, joined by spaces.
function string(__count, __out, __i) {
  __count = 1 + pick(3)
  __out = PIECE[1 + pick(PIECES)]

  for (__i = 2; __i <= __count; __i++) {
    __out = __out " " PIECE[1 + pick(PIECES)]
  }

  return literal(__out)
}

# A random int within a million of zero, and now and then at the edge of
# what every reader holds exactly.
function integer() {
  if (chance(5)) {
    return chance(50) ? "9007199254740991" : "-9007199254740991"
  }

  return (chance(30) ? "-" : "") (pick(1000000))
}

# A random decimal with one to three digits after the point, the last of
# them not zero.
function decimal(__fraction) {
  __fraction = pick(3) == 0 ? (1 + pick(9)) : (pick(3) == 0 ? (10 + pick(90)) : (100 + pick(900)))
  while (__fraction % 10 == 0) {
    __fraction++
  }

  return (chance(30) ? "-" : "") pick(10000) "." __fraction
}

# A random scalar's JSON.
function scalar(__kind) {
  __kind = pick(10)

  if (__kind == 0) {
    return "null"
  }
  if (__kind == 1) {
    return chance(50) ? "true" : "false"
  }
  if (__kind <= 4) {
    return integer()
  }
  if (__kind == 5) {
    return decimal()
  }

  return string()
}

# How many children a collection opened at the stack's current height
# takes: fewer as the tree deepens, none past the size cap.
function children() {
  if (NODES > 40) {
    return 0
  }
  if (N >= 4) {
    return pick(3)
  }

  return pick(5)
}

# Fills KEY[N, 1..LEFT[N]] with distinct keys from the pool, in canonical
# order: the pool holds no key outside the Basic Multilingual Plane, so
# byte order is UTF-16 order, and the keys are compared as text, since awk
# would compare "1" and "007" as numbers. Trims the count when the draws
# collide.
function draw_keys(__i, __j, __k, __drawn) {
  __drawn = 0

  for (__i = 1; __i <= LEFT[N]; __i++) {
    __k = KEYS[1 + pick(KEYS_N)]
    if ((N, __k) in SEEN) {
      continue
    }
    SEEN[N, __k] = 1

    for (__j = __drawn; __j >= 1 && (KEY[N, __j] "") > (__k ""); __j--) {
      KEY[N, __j + 1] = KEY[N, __j]
    }
    KEY[N, __j + 1] = __k
    __drawn++
  }

  LEFT[N] = __drawn
}

# Opens a collection: its bracket, its child count, and for a map its keys.
function open_collection(kind) {
  N++
  NODES++
  KIND[N] = kind
  LEFT[N] = children()
  NEXT[N] = 1
  FIRST[N] = 1
  OUT = OUT ((kind == "map") ? "{" : "[")

  if (kind == "map") {
    clear_seen()
    draw_keys()
  }
}

# Forgets the keys the collection at the stack's height drew before.
function clear_seen(__i) {
  for (__i = 1; __i <= KEYS_N; __i++) {
    delete SEEN[N, KEYS[__i]]
  }
}

# Writes the next child of the collection open: its separator and, under a
# map, its key, then a scalar or a collection of its own.
function write_child() {
  if (!FIRST[N]) {
    OUT = OUT ","
  }
  FIRST[N] = 0

  if (KIND[N] == "map") {
    OUT = OUT literal(KEY[N, NEXT[N]]) ":"
    NEXT[N]++
  }
  LEFT[N]--

  if (chance(N >= 3 ? 20 : 40)) {
    open_collection(chance(55) ? "map" : "list")
  } else {
    OUT = OUT scalar()
  }
}

# Closes the collection open.
function close_collection() {
  OUT = OUT ((KIND[N] == "map") ? "}" : "]")
  N--
}

# Writes the whole value: a scalar, or a root collection filled child by
# child until every collection opened has closed.
function write_value(__kind) {
  __kind = pick(100)

  if (__kind < 10) {
    OUT = scalar()
    return
  }

  open_collection(__kind < 75 ? "map" : "list")
  while (N > 0) {
    if (LEFT[N] == 0) {
      close_collection()
    } else {
      write_child()
    }
  }
}

# The pool of string pieces and of keys: every spelling a reader or a writer
# of JSON or YAML can get wrong.
function fill_pools() {
  PIECES = split("plain text|yes|null|007|1.5|a: b|- x|tab\there|line\nbreak|two\n\nbreaks|quote \" and \\ backslash|café|😀|\001|#hash|~|[flow]|{a: 1}|it's|'single'|0x1F|.5|1e5|true|2026-09-20T18:11:50Z|on|No|trailing |", PIECE, "|")
  KEYS_N = split("a|b|key|Key|_|with space|k.d|k[0]|é|☃|007|on|test/a.bats|a \"q\"|z|y|x|null|1|", KEYS, "|")
}

BEGIN {
  STATE = (seed % 2147483646) + 1
  warm_up()
  fill_pools()
  N = 0
  NODES = 0
  OUT = ""

  write_value()
  print OUT
}
