# Prints the records of a document as a list of maps under other names:
# the record's name under "title", prefixed with the suite's name, its
# status under "state", its reads as they are, and its owner, a null when
# the record has none.

function main(line) {
  tree_line(line)
}

# Prints one record as the element at an index.
function print_record(record, index_in_list, suite) {
  print_open(0, index_in_list, "map")
  print_str(1, "title", suite "/" text_of(member(record, "name")))
  print_node(member(record, "status"), 1, wrap("state"))
  print_node(member(record, "reads"), 1, wrap("reads"))
  print_node(member(record, "owner"), 1, wrap("owner"))
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  suite = text_of(member(ROOT, "suite"))
  printed = 0
  for (record = NODE_FIRST[member(ROOT, "records")]; record != 0; record = NODE_NEXT[record]) {
    print_record(record, printed, suite)
    printed++
  }

  if (printed == 0) {
    print "0.:list"
  }
}

{ main($0) }
