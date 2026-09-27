# A map's values as a list, in the order the map holds them, numbered from
# 0: silt__values past the threshold.
#
#   0."a":int=1
#   0."b":map
#   1."c":int=2   ->  0.0:int=1
#                     0.1:map
#                     1."c":int=2

# What a line last parsed writes after its key: its type, and for a leaf an
# equals sign and its value.
function node_text() {
  return LEAF ? TYPE "=" VALUE : TYPE
}

# Prints a member's own line under the next index and a deeper line as it
# is, and drops the empty collection's one line.
function main() {
  if (is_keyless($0)) {
    return
  }

  if (is_member($0)) {
    parse($0)
    print "0." at ":" node_text()
    at++
    return
  }

  print
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
