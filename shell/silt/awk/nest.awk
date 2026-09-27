# A collection's lines one level deeper than the member they now sit under,
# at depth SILT_DEPTH: __silt__nest past the threshold.

# Prints the line one level deeper than the member it now sits under.
function main() {
  print redepth($0, depth + 1)
}

BEGIN {
  depth = ENVIRON["SILT_DEPTH"] + 0
}

{ main() }
