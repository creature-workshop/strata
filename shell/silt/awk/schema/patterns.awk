# Converts a schema's pattern into a regular expression that awk can match.
#
# JSON Schema patterns use a richer regular expression syntax than awk has.
# This file translates the parts that can be translated and rejects the rest:
#
#   - \d, \w and \s, and their negations \D, \W and \S, are replaced with
#     bracket expressions. They match ASCII characters only.
#   - A repetition in braces, such as a{2,3}, is expanded, because some
#     versions of awk do not support braces.
#   - A group that starts with "(?", a word boundary (\b) and a back
#     reference (\1) cannot be translated, and cause an error.
#
# This file contains functions only. Load after lines.awk and order.awk.
#
#   to_awk_regex("^\\d{2}-[\\w.]+$")  ->  ^[0-9][0-9]-[A-Za-z0-9_.]+$

# Returns the characters that a class letter (d, w or s, in either case)
# stands for, in the form used inside a bracket expression. Returns an empty
# string if the letter is not a class.
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

# Translates an escape sequence that appears outside a bracket expression.
# A class becomes a bracket expression, and any other escape is kept as it
# is. Exits with an error for a word boundary or a back reference.
function escape_outside(letter, pattern, __members) {
  if (letter ~ /^[bB1-9]$/) {
    refuse("pattern uses a feature that awk regular expressions do not support: " pattern)
  }

  __members = class_members(letter)
  if (__members == "") {
    return "\\" letter
  }

  return (letter ~ /^[DWS]$/ ? "[^" : "[") __members "]"
}

# Translates an escape sequence that appears inside a bracket expression. A
# class becomes its characters, and any other escape is kept as it is. Exits
# with an error for a negated class, which cannot be written inside a
# bracket expression.
function escape_inside(letter, pattern) {
  if (letter ~ /^[DWS]$/) {
    refuse("pattern uses a feature that awk regular expressions do not support: " pattern)
  }
  if (class_members(letter) == "") {
    return "\\" letter
  }

  return class_members(letter)
}

# Appends text to the output and records where it starts. If a repetition
# follows, this is the text that gets repeated.
function write_atom(text) {
  ATOM_AT = length(OUT) + 1
  OUT = OUT text
}

# Writes the start of a bracket expression, including a leading "^" and a
# leading "]" if present, because a "]" in that position is a literal
# character and does not close the expression. Returns the number of pattern
# characters consumed.
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

# Writes one character that is inside a bracket expression. A "]" closes the
# expression.
function write_inside(c) {
  OUT = OUT c
  INSIDE = (c != "]")
}

# Writes an opening or closing parenthesis. After a closing parenthesis,
# the whole group is what a following repetition repeats.
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

# Returns the text repeated according to a brace repetition: at least
# "fewest" times, and at most "most" times. If "most" is empty there is no
# upper limit.
#
#   expand_repetition("a", 2, 3)   ->  aa(a)?
#   expand_repetition("a", 2, "")  ->  aaa*
function expand_repetition(atom, fewest, most, __out, __i) {
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

# Handles a brace repetition at the given position in the pattern: {n},
# {n,} or {n,m}. Replaces the preceding text in the output with its expanded
# form. Returns the number of pattern characters consumed, or 0 if the
# braces are not a valid repetition.
function write_repetition(pattern, at, __bounds, __bound, __atom) {
  if (!match(substr(pattern, at), /^\{[0-9]+(,[0-9]*)?\}/)) {
    return 0
  }

  __bounds = substr(pattern, at + 1, RLENGTH - 2)
  split(__bounds, __bound, ",")
  __atom = substr(OUT, ATOM_AT)
  OUT = substr(OUT, 1, ATOM_AT - 1) expand_repetition(__atom, __bound[1] + 0, (index(__bounds, ",") > 0) ? __bound[2] : __bound[1])

  return RLENGTH
}

# Writes one character that is outside a bracket expression, handling the
# characters that have a special meaning. A brace that is not part of a
# valid repetition is written as a literal brace. Returns the number of
# pattern characters consumed.
function write_outside(pattern, at, __c, __took) {
  __c = substr(pattern, at, 1)

  if (__c == "[") {
    return open_bracket(pattern, at)
  }
  if (__c == "(" && substr(pattern, at + 1, 1) == "?") {
    refuse("pattern uses a feature that awk regular expressions do not support: " pattern)
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

# Writes an escape sequence, translating it according to whether it is
# inside or outside a bracket expression.
function write_escape(letter, pattern) {
  if (INSIDE) {
    OUT = OUT escape_inside(letter, pattern)
  } else {
    write_atom(escape_outside(letter, pattern))
  }
}

# Translates a whole pattern and returns the result. OUT holds the output so
# far, and INSIDE is 1 while a bracket expression is open.
function translate_pattern(pattern, __at, __c) {
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

# Returns the translated pattern. Each pattern is translated once and the
# result is cached.
function to_awk_regex(pattern) {
  if (!(pattern in ERE)) {
    ERE[pattern] = translate_pattern(pattern)
  }

  return ERE[pattern]
}

# Returns 1 if the text contains a match for the pattern.
function matches(text, pattern) {
  return text ~ to_awk_regex(pattern)
}
