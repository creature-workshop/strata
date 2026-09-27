# A schema's pattern as the extended regular expression awk matches with.
# The classes \d, \w and \s and their opposites are spelled out, inside a
# bracket expression and outside one.
# A repetition between braces is written out, since not every awk reads the
# braces. What an extended regular expression has no spelling for is
# refused: a group opening on "(?", a word boundary and a back reference.
# It holds functions alone. Loaded after lines.awk and order.awk.
#
#   as_ere("^\\d{2}-[\\w.]+$")  ->  ^[0-9][0-9]-[A-Za-z0-9_.]+$

# The members of the class a letter names, as a bracket expression holds
# them, or nothing when the letter names no class.
function class_members(letter) {
  if (letter == "d" || letter == "D") {
    return "0-9"
  }
  if (letter == "w" || letter == "W") {
    return "A-Za-z0-9_"
  }
  if (letter == "s" || letter == "S") {
    return " \t\n\r\f\v"
  }

  return ""
}

# An escape met outside a bracket expression: a class as a bracket
# expression of its own, and any other as written. Refuses a word boundary
# and a back reference.
function escape_outside(letter, pattern, __members) {
  if (letter ~ /^[bB1-9]$/) {
    refuse("a pattern an extended regular expression cannot spell: " pattern)
  }

  __members = class_members(letter)
  if (__members == "") {
    return "\\" letter
  }

  return (letter ~ /^[DWS]$/ ? "[^" : "[") __members "]"
}

# An escape met inside a bracket expression: a class as its members, and
# any other as written. Refuses the opposite of a class, which a bracket
# expression cannot hold.
function escape_inside(letter, pattern) {
  if (letter ~ /^[DWS]$/) {
    refuse("a pattern an extended regular expression cannot spell: " pattern)
  }
  if (class_members(letter) == "") {
    return "\\" letter
  }

  return class_members(letter)
}

# Appends text to the expression being written, as the atom a repetition
# after it would repeat.
function write_atom(text) {
  ATOM_AT = length(OUT) + 1
  OUT = OUT text
}

# Opens a bracket expression, a "^" and a "]" that open it taken with it,
# since a "]" there is a member and closes nothing. Answers how many
# characters of the pattern it took.
function open_bracket(pattern, at, __opener) {
  __opener = "["
  if (substr(pattern, at + length(__opener), 1) == "^") {
    __opener = __opener "^"
  }
  if (substr(pattern, at + length(__opener), 1) == "]") {
    __opener = __opener "]"
  }

  write_atom(__opener)
  INSIDE = 1

  return length(__opener)
}

# One character inside a bracket expression, which a "]" closes.
function write_inside(c) {
  OUT = OUT c
  INSIDE = (c != "]")
}

# Opens or closes a group: the atom a closed group leaves is the whole of
# it, from its opener.
function write_group(c) {
  if (c == "(") {
    GROUP_AT[++GROUPS] = length(OUT) + 1
    OUT = OUT c
    return
  }

  OUT = OUT c
  if (GROUPS > 0) {
    ATOM_AT = GROUP_AT[GROUPS--]
  }
}

# The atom written <fewest> times, then as often as the bound allows: any
# number of times more when <most> is empty, and up to <most> in all
# otherwise.
function repeated(atom, fewest, most, __out, __i) {
  __out = ""

  for (__i = 1; __i <= fewest; __i++) {
    __out = __out atom
  }
  if (most == "") {
    return __out atom "*"
  }
  for (__i = fewest + 1; __i <= most; __i++) {
    __out = __out "(" atom ")?"
  }

  return __out
}

# Writes the repetition the pattern spells at <at> between braces, {n},
# {n,} or {n,m}, as the atom before it written out that often, since not
# every awk reads the braces. Answers how many characters of the pattern it
# took, 0 when the braces spell no repetition.
function write_repetition(pattern, at, __bounds, __bound, __atom) {
  if (!match(substr(pattern, at), /^\{[0-9]+(,[0-9]*)?\}/)) {
    return 0
  }

  __bounds = substr(pattern, at + 1, RLENGTH - 2)
  split(__bounds, __bound, ",")
  __atom = substr(OUT, ATOM_AT)
  OUT = substr(OUT, 1, ATOM_AT - 1) repeated(__atom, __bound[1] + 0, (index(__bounds, ",") > 0) ? __bound[2] : __bound[1])

  return RLENGTH
}

# One character outside a bracket expression, with what it opens; a brace
# that spells no repetition is written as the character it is. Answers how
# many characters of the pattern it took.
function write_outside(pattern, at, __c, __took) {
  __c = substr(pattern, at, 1)

  if (__c == "[") {
    return open_bracket(pattern, at)
  }
  if (__c == "(" && substr(pattern, at + 1, 1) == "?") {
    refuse("a pattern an extended regular expression cannot spell: " pattern)
  }
  if (__c == "(" || __c == ")") {
    write_group(__c)
    return 1
  }
  if (__c == "{") {
    __took = write_repetition(pattern, at)
    if (__took > 0) {
      return __took
    }
  }
  if (__c == "{" || __c == "}") {
    write_atom("[" __c "]")
    return 1
  }

  if (ORD[__c] >= 128 && ORD[__c] < 192) {
    OUT = OUT __c
  } else {
    write_atom(__c)
  }

  return 1
}

# An escape and the letter after it, inside a bracket expression or
# outside one.
function write_escape(letter, pattern) {
  if (INSIDE) {
    OUT = OUT escape_inside(letter, pattern)
  } else {
    write_atom(escape_outside(letter, pattern))
  }
}

# The pattern as an extended regular expression, read from its start, OUT
# holding what is written and INSIDE telling whether a bracket expression
# is open.
function translated(pattern, __at, __c) {
  OUT = ""
  INSIDE = 0
  GROUPS = 0
  ATOM_AT = 1
  __at = 1

  while (__at <= length(pattern)) {
    __c = substr(pattern, __at, 1)

    if (__c == "\\") {
      write_escape(substr(pattern, __at + 1, 1), pattern)
      __at = __at + 2
    } else if (INSIDE) {
      write_inside(__c)
      __at++
    } else {
      __at = __at + write_outside(pattern, __at)
    }
  }

  return OUT
}

# The pattern as an extended regular expression, translated once and kept.
function as_ere(pattern) {
  if (!(pattern in ERE)) {
    ERE[pattern] = translated(pattern)
  }

  return ERE[pattern]
}

# Whether the text holds a match of the pattern.
function matches(text, pattern) {
  return text ~ as_ere(pattern)
}
