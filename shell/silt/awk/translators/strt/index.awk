# The index library the .strt programs load first, with -f after lines.awk:
# the corpus's keys read from the spill file, a code for each key and a key
# for each code, and the natural primitives' codes (ADR.3@strata) each way.
# It holds functions and the tables BEGIN fills, so no rule of it runs on
# any line.

# Reads the index from the spill file, the corpus's keys as a list of str in
# code order: KEY_OF[code] is the key literal with that code, CODE_OF[key] the
# code of a key literal, and KEYS how many there are.
function load_keys(__line) {
  KEYS = 0

  while ((getline __line < ENVIRON["SILT_SPILL"]) > 0) {
    if (is_keyless(__line)) {
      continue
    }
    parse(__line)
    if (TYPE != "str") {
      refuse("the index holds str keys, not a " TYPE)
    }
    KEY_OF[KEY + 0] = VALUE
    CODE_OF[VALUE] = KEY + 0
    KEYS++
  }

  close(ENVIRON["SILT_SPILL"])
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
