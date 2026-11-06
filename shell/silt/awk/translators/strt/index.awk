# The index library the .strt programs load first, with -f after lines.awk:
# the corpus's keys, read ahead of the document on stdin or from a file, a
# code for each key and a key for each code, and the natural primitives'
# codes (ADR.3@strata) each way.
# It holds functions and the tables BEGIN fills, so no rule of it runs on
# any line.

# Reads the index, the corpus's keys as a list of str in code order:
# KEY_OF[code] is the key literal with that code, CODE_OF[key] the code of a
# key literal, and KEYS how many there are. The writer sends the index ahead
# of the document on stdin; the reader, whose document is the caller's
# stdin, names a file holding it in SILT_INDEX_FILE.
function load_keys(__i) {
  KEYS = 0

  if (ENVIRON["SILT_INDEX_FILE"] != "") {
    read_index_file(ENVIRON["SILT_INDEX_FILE"])
  } else {
    read_ahead()
  }

  for (__i = 1; __i <= AHEADS; __i++) {
    take_key(AHEAD[__i])
  }
}

# Reads the index from the file into AHEAD[1..AHEADS], as read_ahead reads
# one sent on stdin.
function read_index_file(file, __line) {
  AHEADS = 0

  while ((getline __line < file) > 0) {
    AHEAD[++AHEADS] = __line
  }

  close(file)
}

# Takes one line of the index: the empty list's keyless line holds no key;
# any other is a str whose index is its code, and is refused otherwise.
function take_key(line) {
  if (is_keyless(line)) {
    return
  }

  parse(line)
  if (TYPE != "str") {
    refuse("the index holds str keys, not a " TYPE)
  }
  KEY_OF[KEY + 0] = VALUE
  CODE_OF[VALUE] = KEY + 0
  KEYS++
}

# Fills NAME_OF, the natural primitive a type code names, and TYPE_CODE, the
# code of a type name.
function load_types(__code) {
  NAME_OF["0"] = "null"
  NAME_OF["-1"] = "map"
  NAME_OF["-2"] = "list"
  NAME_OF["-3"] = "str"
  NAME_OF["-4"] = "bool"
  NAME_OF["-5"] = "int"
  NAME_OF["-6"] = "float"
  NAME_OF["-7"] = "time-rfc3339-utc"

  for (__code in NAME_OF) {
    TYPE_CODE[NAME_OF[__code]] = __code
  }
}

# Ends the run naming the line that cannot be translated.
function refuse_line(why) {
  refuse("line " NR ": " why ": " $0)
}
