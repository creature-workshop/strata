# How the writer spells a string and a key in TOML, so that the reader
# reads each back as the same text: a string as a basic string, in double
# quotes with TOML's escapes, and a key bare where TOML allows and as a
# basic string otherwise. Loaded after awk/lines.awk by every program that
# writes TOML.
#
#   toml_basic("say \"hi\"")  ->  "say \"hi\""
#   toml_key("name")          ->  name
#   toml_key("google.com")    ->  "google.com"

# The text as a TOML basic string: in double quotes, a quote and a
# backslash escaped, a control character by its letter where TOML has one
# and as \u00XX otherwise, a delete as \u007f, and every other character as
# it is.
function toml_basic(text, __out, __i, __c) {
  __out = ""

  for (__i = 1; __i <= length(text); __i++) {
    __c = substr(text, __i, 1)
    __out = __out ((__c == "\177") ? "\\u007f" : escape_char(__c))
  }

  return "\"" __out "\""
}

# The text as a TOML key: bare when it is letters, digits, underscores and
# dashes alone, and a basic string otherwise.
function toml_key(text) {
  if (text ~ /^[A-Za-z0-9_-]+$/) {
    return text
  }

  return toml_basic(text)
}
