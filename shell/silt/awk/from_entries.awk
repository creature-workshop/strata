# A map from a list of its keys and values, one member for each element:
# silt__from_entries past the threshold, and for a list that holds a key
# twice. A member stays where the first element with its key put it and
# has the value of the last. Loaded after lines.awk, order.awk and
# elements.awk.
#
#   0.0:map
#   1."key":str="a"
#   1."value":int=1   ->  0."a":int=1

# Keeps every line for END.
function main() {
  keep($0)
}

# Reads every element as an entry, in order.
function read_entries(__i) {
  for (__i = 1; __i <= MEMBERS; __i++) {
    read_entry(__i)
  }
}

# Reads element i: its key into KEY_TEXT[i], and the lines of its value
# into VALUE_FROM[i] and VALUE_TO[i], which stay 0 when it has no value.
# Notes the place of a key met for the first time, and the last element
# that has each key. Refuses an element that is not a map, and one without
# a scalar under "key".
function read_entry(i, __at, __part) {
  parse(INPUT[FIRST[i]])
  if (TYPE != "map") {
    refuse("from_entries takes a map in every element, not a " TYPE " at index " KEY_OF[i])
  }

  KEY_TEXT[i] = ""
  VALUE_FROM[i] = 0
  VALUE_TO[i] = 0
  __part = ""

  for (__at = FIRST[i] + 1; __at <= LAST[i]; __at++) {
    parse(INPUT[__at])
    if (DEPTH == 1) {
      __part = read_entry_member(i, __at)
    } else if (__part == "value") {
      VALUE_TO[i] = __at
    }
  }

  if (KEY_TEXT[i] == "") {
    refuse("from_entries takes a scalar under \"key\" in every element, and the element at index " KEY_OF[i] " has none")
  }

  if (!(KEY_TEXT[i] in LATEST)) {
    PLACED++
    KEY_AT_PLACE[PLACED] = KEY_TEXT[i]
  }
  LATEST[KEY_TEXT[i]] = i
}

# Reads the depth-1 line last parsed as a member of element i, and says
# which member it is: "key", "value", or the empty string for any other.
# The key is kept as a line writes a key: a str as it is, and any other
# scalar as the str that spells its value.
function read_entry_member(i, at) {
  if (KEY == "\"key\"") {
    if (LEAF) {
      KEY_TEXT[i] = (TYPE == "str") ? VALUE : wrap(VALUE)
    }
    return "key"
  }

  if (KEY == "\"value\"") {
    VALUE_FROM[i] = at
    VALUE_TO[i] = at
    return "value"
  }

  return ""
}

# Prints the members: each key in the place of the first element that had
# it, with the value of the last element that had it.
function print_members(__place) {
  for (__place = 1; __place <= PLACED; __place++) {
    print_member_of(LATEST[KEY_AT_PLACE[__place]])
  }

  if (PLACED == 0) {
    print "0.:map"
  }
}

# Prints element i as a member: its key with what its value writes after
# it, a null when it has no value, and the lines under its value one level
# up.
function print_member_of(i, __at) {
  if (VALUE_FROM[i] == 0) {
    print "0." KEY_TEXT[i] ":null"
    return
  }

  parse(INPUT[VALUE_FROM[i]])
  print "0." KEY_TEXT[i] ":" (LEAF ? TYPE "=" VALUE : TYPE)

  for (__at = VALUE_FROM[i] + 1; __at <= VALUE_TO[i]; __at++) {
    print redepth(INPUT[__at], -1)
  }
}

BEGIN {
  elements_begin()
  PLACED = 0
}

END {
  if (REFUSED) {
    exit 1
  }

  close_members()
  read_entries()
  print_members()
}

{ main() }
