# Prints the name of every record in upper case, as a list of strs. It
# calls shouted(), which the library shout.awk defines, so it runs only
# with that library loaded.

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

  printed = 0
  for (record = NODE_FIRST[member(ROOT, "records")]; record != 0; record = NODE_NEXT[record]) {
    print "0." printed ":str=" wrap(shouted(text_of(member(record, "name"))))
    printed++
  }
}

{ main($0) }
