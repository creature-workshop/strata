# A schema's pattern as the extended regular expression awk matches with.
# The classes \d, \w and \s and their opposites are spelled out, inside a
# bracket expression and outside one. What an extended regular expression
# has no spelling for is refused: a group opening on "(?", a word boundary
# and a back reference. It holds functions alone. Loaded after lines.awk.
#
#   as_ere("^\\d{3}-[\\w.]+$")  ->  ^[0-9]{3}-[A-Za-z0-9_.]+$

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

# The pattern as an extended regular expression, read one character at a
# time, INSIDE telling whether a bracket expression is open.
function translated(pattern, __out, __i, __c) {
  __out = ""
  INSIDE = 0

  for (__i = 1; __i <= length(pattern); __i++) {
    __c = substr(pattern, __i, 1)

    if (__c == "\\") {
      __i++
      __c = substr(pattern, __i, 1)
      __out = __out (INSIDE ? escape_inside(__c, pattern) : escape_outside(__c, pattern))
      continue
    }
    if (!INSIDE && __c == "(" && substr(pattern, __i + 1, 1) == "?") {
      refuse("a pattern an extended regular expression cannot spell: " pattern)
    }

    INSIDE = INSIDE ? (__c != "]") : (__c == "[")
    __out = __out __c
  }

  return __out
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
