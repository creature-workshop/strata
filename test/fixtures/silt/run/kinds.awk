# Prints what the document is, as a map: its type, how many members it
# has, and the document itself under "whole".

function main(line) {
  tree_line(line)
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  print_str(0, "type", NODE_TYPE[ROOT])
  print "0." wrap("members") ":int=" NODE_COUNT[ROOT]
  print_node(ROOT, 0, wrap("whole"))
  print "0." wrap("alone") ":list"
  print "1.0:map"
  print "2." wrap("document") ":str=" wrap("see below")
}

{ main($0) }
