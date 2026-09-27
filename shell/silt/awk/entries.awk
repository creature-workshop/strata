# A map as a list with one {key, value} map per member, in the order the
# map holds them: silt__entries past the threshold.
#
#   0."a":int=1   ->  0.0:map
#                     1."key":str="a"
#                     1."value":int=1

# What a line last parsed writes after its key: its type, and for a leaf an
# equals sign and its value.
function node_text() {
  return LEAF ? TYPE "=" VALUE : TYPE
}

# Prints an entry for a member's own line, and a deeper line one level
# down, under the entry's value. Drops the empty map's one line.
function main() {
  if (is_keyless($0)) {
    return
  }

  if (is_member($0)) {
    parse($0)
    print "0." at ":map"
    print "1.\"key\":str=" KEY
    print "1.\"value\":" node_text()
    at++
    return
  }

  print redepth($0, 1)
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
