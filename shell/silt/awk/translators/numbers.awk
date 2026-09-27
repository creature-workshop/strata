# The spellings of a number a translator meets brought to ADR.20's form,
# shared by every reader that takes a spelling JSON does not: the digits of
# a number in another base as a decimal int, exact at any length since the
# arithmetic runs on the digits as text, and a decimal number's text with
# its plus sign and its leading zeros off and a digit on both sides of its
# point. Loaded from awk/translators ahead of a reader's own files.
#
#   from_base("1F", 16)  ->  31      decimal_form("+05")  ->  5
#   from_base("17", 8)   ->  15      decimal_form(".5")   ->  0.5

# The digits of a number in <base> as a decimal int: each digit in turn
# multiplies the decimal text by the base and adds itself, so the value
# stays exact past 2^53, where awk's own numbers do not.
function from_base(digits, base, __value, __i) {
  __value = "0"

  for (__i = 1; __i <= length(digits); __i++) {
    __value = times_plus(__value, base, index("0123456789abcdef", tolower(substr(digits, __i, 1))) - 1)
  }

  return __value
}

# The decimal text <value> times <factor> plus <addend>, as decimal text,
# carried from its last digit to its first.
function times_plus(value, factor, addend, __out, __i, __carry, __digit) {
  __out = ""
  __carry = addend

  for (__i = length(value); __i >= 1; __i--) {
    __digit = substr(value, __i, 1) * factor + __carry
    __out = (__digit % 10) __out
    __carry = int(__digit / 10)
  }

  while (__carry > 0) {
    __out = (__carry % 10) __out
    __carry = int(__carry / 10)
  }

  return __out
}

# A decimal number's text in ADR.20's form: its sign only when minus, its
# integer part without leading zeros, its fraction with a digit after the
# point, and its exponent as written.
function decimal_form(text, __sign, __exponent, __whole, __fraction, __at) {
  __sign = (text ~ /^-/) ? "-" : ""
  sub(/^[-+]/, "", text)

  __exponent = ""
  __at = match(text, /[eE]/)
  if (__at > 0) {
    __exponent = substr(text, __at)
    text = substr(text, 1, __at - 1)
  }

  __whole = text
  __fraction = ""
  if (index(text, ".") > 0) {
    __whole = substr(text, 1, index(text, ".") - 1)
    __fraction = "." substr(text, index(text, ".") + 1)
  }
  if (__fraction == ".") {
    __fraction = ".0"
  }

  sub(/^0+/, "", __whole)
  if (__whole == "") {
    __whole = "0"
  }

  return __sign __whole __fraction __exponent
}
