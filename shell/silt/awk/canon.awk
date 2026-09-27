# The document with every map's members in canonical order: silt__canon.
# Canonical order is RFC 8785's, the keys compared by their UTF-16 code
# units, so a map built in call order and the same map built in another
# come out the same bytes. Lists keep their order, and every line keeps its
# text. Loaded after lines.awk and order.awk, which holds the order.

# Keeps every line, with its sort key, for END.
function main() {
  take($0)
}

BEGIN {
  order_begin()
}

END {
  print_ordered()
}

{ main() }
