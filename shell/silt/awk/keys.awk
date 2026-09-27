# The members' keys as a list document, str leaves for a map's key literals
# and int leaves for a list's indices: silt__keys past the threshold.

# Adds a member's key as the next element of the list: a str leaf for a map's
# key literal, an int leaf for a list's index.
function main() {
  if (!is_member($0)) {
    return
  }

  parse($0)

  if (is_name(KEY)) {
    print "0." at ":str=" KEY
  } else {
    print "0." at ":int=" KEY
  }

  at++
}

BEGIN {
  at = 0
}

END {
  if (at == 0) {
    print "0.:list"
  }
}

{ main() }
