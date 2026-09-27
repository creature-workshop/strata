# A collection's lines one level deeper than the member they now sit under,
# at depth SILT_DEPTH: __silt__nest past the threshold.

BEGIN {
  depth = ENVIRON["SILT_DEPTH"] + 0
}

{
  print redepth($0, depth + 1)
}
