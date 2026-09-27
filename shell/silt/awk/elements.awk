# The members of a document read whole, for the set operations and merge:
# the lines each spans, its key, and the canonical text of its value, by
# which two members are alike the way silt__equals says. The document on
# stdin is document 1 and the one in SILT_SPILL document 2, their members
# numbered on from each other. It holds functions alone; a program's main
# hands it each line of stdin with keep(), reads the spill with
# keep_spill(), and asks for members from END. Loaded after lines.awk and
# order.awk.
#
#   INPUT[1..INPUTS]   every line kept
#   MEMBERS            how many members both documents hold
#   FIRST[i], LAST[i]  the lines member i spans
#   KEY_OF[i]          member i's key as its line writes it
#   DOC_OF[i]          which document member i belongs to, 1 or 2

# Keeps one line of the document being read; a depth-0 line with a key
# opens a member, and the empty collection's keyless line opens none.
function keep(line) {
  INPUT[++INPUTS] = line

  if (!is_member(line)) {
    return
  }

  parse(line)
  MEMBERS++
  FIRST[MEMBERS] = INPUTS
  KEY_OF[MEMBERS] = KEY
  DOC_OF[MEMBERS] = DOC
  if (MEMBERS > 1) {
    LAST[MEMBERS - 1] = INPUTS - 1
  }
}

# Reads the second document from the spill file, its lines kept after the
# first's, whose last member ends where the first document does.
function keep_spill(__line) {
  close_members()
  DOC = 2

  while ((getline __line < ENVIRON["SILT_SPILL"]) > 0) {
    keep(__line)
  }

  close(ENVIRON["SILT_SPILL"])
}

# Closes the last member of the document being read, which ends where its
# lines end.
function close_members() {
  if (MEMBERS > 0 && DOC_OF[MEMBERS] == DOC) {
    LAST[MEMBERS] = INPUTS
  }
}

# The line of member i's value as a document of its own: its own line as a
# keyless root, or a deeper line moved up so the value's members sit at
# depth 0.
function value_line(i, at, __line) {
  __line = INPUT[at]

  if (at == FIRST[i]) {
    parse(__line)
    return LEAF ? "0.:" TYPE "=" VALUE : "0.:" TYPE
  }

  return redepth(__line, -1)
}

# The canonical text of member i's value, every map in it in canonical
# order, so two values that are the same are the same text. A collection
# that holds members is spelled by them alone, its own line dropped.
function identity_of(i, __at, __from, __text, __k) {
  LINES = 0
  __from = (LAST[i] > FIRST[i]) ? FIRST[i] + 1 : FIRST[i]

  for (__at = __from; __at <= LAST[i]; __at++) {
    take(value_line(i, __at))
  }
  sort_lines()

  __text = ""
  for (__k = 1; __k <= LINES; __k++) {
    __text = __text LINE[ORDER[__k]] "\n"
  }

  return __text
}

# Prints member i as the element at <position> of a list: its own line
# under that index, and its deeper lines as they are.
function print_element(i, position, __at) {
  print "0." position substr(INPUT[FIRST[i]], index(INPUT[FIRST[i]], ":"))

  for (__at = FIRST[i] + 1; __at <= LAST[i]; __at++) {
    print INPUT[__at]
  }
}

# Prints member i as it was read, its key as its line writes it.
function print_member(i, __at) {
  for (__at = FIRST[i]; __at <= LAST[i]; __at++) {
    print INPUT[__at]
  }
}

# Readies the tables and the order, and starts on document 1.
function elements_begin() {
  order_begin()
  INPUTS = 0
  MEMBERS = 0
  DOC = 1
}
