# The SILT document on stdin as the .strh text a corpus keeps: silt__to_strh.
# Every line gets its LID and a space in front, drawn as ecuyer1988-doc-line
# draws it (ADR.9@strata): the document half from the doc-seed and the
# document's number, the line half from the line-seed and the line's place,
# each eight lowercase hex characters. The doc-seed, the line-seed and the
# number are sent ahead of it as a list of three ints. Every product is split
# so none passes 2^48, exact in awk. Refused, naming the line: a line that is
# not SILT, and an empty document. Loaded after lines.awk.
#
#   0."runner":str="bats"  as document 1 under the seeds 1299709 and 104729
#     ->  67e924b179c7e1f3 0."runner":str="bats"

# Reads the doc-seed, the line-seed and the number, sent ahead of the
# document as a list of three ints, into SEED[0], SEED[1] and SEED[2].
function load_seeds(__n) {
  read_ahead()

  for (__n = 1; __n <= AHEADS; __n++) {
    parse(AHEAD[__n])
    SEED[__n - 1] = VALUE + 0
  }
}

# a times b modulo m, exact under 2^53: b is split at sixteen bits, so no
# product passes 2^48.
function mulmod(a, b, m, __high, __low) {
  __high = int(b / 65536)
  __low = b - __high * 65536

  return ((a * __high % m) * 65536 + a * __low) % m
}

# base to the power exponent modulo m, by repeated squaring.
function powmod(base, exponent, m, __result) {
  __result = 1

  while (exponent > 0) {
    if (exponent % 2 == 1) {
      __result = mulmod(__result, base, m)
    }
    base = mulmod(base, base, m)
    exponent = int(exponent / 2)
  }

  return __result
}

# A number as eight lowercase hex characters, zeros in front.
function hex8(n) {
  return sprintf("%08x", n)
}

# One line: checked as SILT, written with its LID in front, and the line half
# moved on to the next line.
function main() {
  parse($0)
  print DOC_HALF hex8(LINE_STATE) " " $0
  LINE_STATE = mulmod(LINE_STATE, LINE_MULTIPLIER, LINE_MODULUS)
}

BEGIN {
  DOC_MULTIPLIER = 40692
  DOC_MODULUS = 2147483399
  LINE_MULTIPLIER = 40014
  LINE_MODULUS = 2147483563
  load_seeds()
  DOC_HALF = hex8(mulmod(powmod(DOC_MULTIPLIER, SEED[2] + 1, DOC_MODULUS), SEED[0], DOC_MODULUS))
  LINE_STATE = mulmod(LINE_MULTIPLIER, SEED[1], LINE_MODULUS)
}

END {
  if (REFUSED) {
    exit 1
  }
  if (NR == 0) {
    refuse("an empty document holds no value")
  }
}

{ main() }
