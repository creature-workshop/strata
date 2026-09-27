# The YAML document on stdin as a SILT document, every map in canonical
# order: silt__from_yaml. It reads the YAML a config or a pipeline file is
# written in: block mappings and sequences, plain and quoted scalars, literal
# and folded blocks, flow collections on one line, and comments. What it
# does not read it refuses, naming the line: anchors and aliases, tags, merge
# keys, complex keys, directives, a second document, and a scalar or a flow
# collection that runs over lines. Loaded after lines.awk, order.awk,
# translators/write.awk and the files beside this one.
#
#   a:            ->  0."a":list
#     - 1             1.0:int=1
#     - x             1.1:str="x"

# Keeps the line for END, when the whole document is read.
function main() {
  keep_line($0)
}

BEGIN {
  order_begin()
  Y_N = 0
}

END {
  read_tree()
  print_ordered()
}

{ main() }
