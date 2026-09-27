# The value a bare token of TOML spells, a bool, a number or a date-time,
# as a node of the reader's tree. A number is an int or a float when its
# spelling is one of ADR.20's patterns, and otherwise the map ADR.20 gives
# a spelling the target cannot carry: its value in ADR.20's form beside the
# spelling and the format. Loaded after awk/lines.awk, translators/write.awk
# and translators/numbers.awk, and text.awk, times.awk and tree.awk beside
# this one.
#
#   token_node("1_000")  ->  0."n":map
#                            1."format":str="toml"
#                            1."spelling":str="1_000"
#                            1."value":int=1000

# The node of a bare token: a bool, a number or a date-time. Refuses any
# other token.
function token_node(token) {
  if (token == "true" || token == "false") {
    return scalar_node("bool", token)
  }
  if (is_toml_int(token) || is_toml_float(token)) {
    return number_node(token)
  }
  if (is_toml_time(token)) {
    return time_node(token)
  }

  refuse_toml("not a TOML value: " token)
}

# Whether the token is an integer as TOML spells one: decimal with a sign
# and underscores between digits, or hex, octal or binary after its prefix.
function is_toml_int(token) {
  if (token ~ /^[-+]?(0|[1-9](_?[0-9])*)$/) {
    return 1
  }

  return token ~ /^0x[0-9A-Fa-f](_?[0-9A-Fa-f])*$/ || token ~ /^0o[0-7](_?[0-7])*$/ || token ~ /^0b[01](_?[01])*$/
}

# Whether the token is a float as TOML spells one: a decimal integer with a
# fraction, an exponent or both, or inf or nan with a sign.
function is_toml_float(token) {
  if (token ~ /^[-+]?(inf|nan)$/) {
    return 1
  }
  if (token !~ /[.eE]/) {
    return 0
  }

  return token ~ /^[-+]?(0|[1-9](_?[0-9])*)(\.[0-9](_?[0-9])*)?([eE][-+]?[0-9](_?[0-9])*)?$/
}

# The node of a number token: a scalar when ADR.20 spells it so, and the
# map that keeps the spelling otherwise.
function number_node(token, __adr) {
  __adr = adr_toml_number(token)

  if (__adr == token) {
    return scalar_node(number_type(token), token)
  }

  return spelling_node(token, number_type(__adr), __adr)
}

# The token's number as ADR.20 spells it: its underscores out, a hex, an
# octal or a binary int in decimal, a plus sign off, and inf and nan with no
# sign but the minus of -inf.
function adr_toml_number(token, __text) {
  __text = token
  gsub(/_/, "", __text)

  if (__text ~ /^0x/) {
    return from_base(substr(__text, 3), 16)
  }
  if (__text ~ /^0o/) {
    return from_base(substr(__text, 3), 8)
  }
  if (__text ~ /^0b/) {
    return from_base(substr(__text, 3), 2)
  }
  if (__text ~ /^[-+]?inf$/) {
    return (__text ~ /^-/) ? "-inf" : "inf"
  }
  if (__text ~ /^[-+]?nan$/) {
    return "nan"
  }

  return decimal_form(__text)
}
