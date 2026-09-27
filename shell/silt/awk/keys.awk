# The members' keys as a list document, str leaves for a map's key literals
# and int leaves for a list's indices: silt__keys past the threshold.
BEGIN { at = 0 }

is_member($0) {
  parse($0)
  if (substr(KEY, 1, 1) == "\"") { print "0." at ":str=" KEY } else { print "0." at ":int=" KEY }
  at++
}

END { if (at == 0) { print "0.:list" } }
