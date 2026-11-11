# Prints one line of plain text about the records of a document: how many
# have the status named by the argument "status", their names joined with
# the argument "separator", the tries of the last record or the word none,
# and the first key of a second document, given with --with.

function main(line) {
  tree_line(line)
}

# The names of the records whose status is the one wanted, joined.
function names_with_status(records, status, separator, __record, __names, __count) {
  __names = ""
  __count = 0

  for (__record = NODE_FIRST[records]; __record != 0; __record = NODE_NEXT[__record]) {
    if (text_of(member(__record, "status")) == status) {
      __names = __names (__count > 0 ? separator : "") text_of(member(__record, "name"))
      __count++
    }
  }

  return __count " " __names
}

BEGIN {
  OTHER = tree_ahead()
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  records = member(ROOT, "records")
  last = child(records, NODE_COUNT[records] - 1)
  print names_with_status(records, arg("status"), arg("separator")) \
    " | tries " text_or(member(last, "tries"), "none") \
    " | owner present " is_present(member(child(records, 0), "owner")) \
    " | other opens on " name_of(NODE_FIRST[OTHER])
}

{ main($0) }
