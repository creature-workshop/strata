# The sum of a list of numbers, as a number document: silt__sum past the
# threshold, and for a list that holds a number with a fraction. The answer
# is an int when every element is one, and a float otherwise.
#
#   0.0:int=1
#   0.1:float=1.5   ->  0.:float=2.5

# The total as a float spells it: the fewest digits that read back as the
# same number, with a fraction or an exponent so it does not read as an int.
function float_text(total, __text) {
  __text = sprintf("%.15g", total)
  if (__text + 0 != total) {
    __text = sprintf("%.17g", total)
  }
  if (__text !~ /[.e]/) {
    __text = __text ".0"
  }

  return __text
}

# Adds an element's own line to the total. Refuses an element that is not a
# number.
function main() {
  if (!is_member($0)) {
    return
  }

  parse($0)
  if (TYPE != "int" && TYPE != "float") {
    refuse("sum takes numbers, not a " TYPE " at index " KEY)
  }
  if (TYPE == "float") {
    fraction = 1
  }
  total += VALUE
}

BEGIN {
  total = 0
  fraction = 0
}

END {
  if (REFUSED) {
    exit 1
  }

  if (fraction) {
    print "0.:float=" float_text(total)
  } else {
    printf "0.:int=%d\n", total
  }
}

{ main() }
