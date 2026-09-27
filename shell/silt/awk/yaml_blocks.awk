# A YAML block scalar, the lines under a "|" or a ">", written into the SILT
# writer as one str. A literal block keeps its line breaks; a folded one
# joins a line to the next with a space, a blank line standing for a line
# break and a line indented further kept on its own. The "-" and "+" after
# the mark strip or keep the line breaks at the end, and an indentation
# digit there is refused. Loaded after write.awk and yaml_lines.awk.
#
#   key: |          key: >-
#     a               a
#     b               b
#   -> "a\nb\n"     -> "a b"

# Whether the text is the mark that opens a block scalar.
function is_block_header(text) {
  if (text ~ /^[|>][-+]?[0-9]/) {
    refuse_yaml("a block scalar with an indentation digit")
  }

  return text ~ /^[|>][-+]?$/
}

# Whether raw line i belongs to a block under a node indented by <parent>:
# it holds nothing, or it is indented further.
function block_holds(i, parent) {
  return Y_RAW[i] ~ /^ *$/ || indent_of(Y_RAW[i]) > parent
}

# Gathers the block's lines into BLOCK[1..n], the block's own indentation
# off, and steps past them. Returns n.
function block_gather(parent, __n, __i, __indent) {
  __indent = -1
  __n = 0

  for (__i = Y_POS; __i <= Y_N && block_holds(__i, parent); __i++) {
    if (__indent < 0 && Y_RAW[__i] !~ /^ *$/) {
      __indent = indent_of(Y_RAW[__i])
    }
    BLOCK[++__n] = (Y_RAW[__i] ~ /^ *$/) ? "" : substr(Y_RAW[__i], __indent + 1)
  }

  Y_POS = __i
  return __n
}

# How many of BLOCK[1..n] are lines past the last one that holds something.
function block_trailing(n, __count) {
  __count = 0

  while (n - __count >= 1 && BLOCK[n - __count] == "") {
    __count++
  }

  return __count
}

# What joins folded line i to the one before it: nothing after a blank
# line, which has already stood for the break; a line break when either
# line is indented further; a space otherwise.
function fold_joint(i) {
  if (BLOCK[i - 1] == "") {
    return ""
  }
  if (BLOCK[i] ~ /^ / || BLOCK[i - 1] ~ /^ /) {
    return "\n"
  }

  return " "
}

# BLOCK[1..n] as a folded block's text.
function block_folded(n, __out, __i) {
  __out = BLOCK[1]

  for (__i = 2; __i <= n; __i++) {
    if (BLOCK[__i] == "") {
      __out = __out "\n"
    } else {
      __out = __out fold_joint(__i) BLOCK[__i]
    }
  }

  return __out
}

# BLOCK[1..n] as a literal block's text.
function block_literal(n, __out, __i) {
  __out = BLOCK[1]

  for (__i = 2; __i <= n; __i++) {
    __out = __out "\n" BLOCK[__i]
  }

  return __out
}

# The line breaks a block's text ends with: none for "-", every one the
# block had for "+", and one otherwise.
function block_ending(header, trailing, __out) {
  if (header ~ /-$/) {
    return ""
  }

  __out = "\n"
  while (header ~ /\+$/ && trailing-- > 0) {
    __out = __out "\n"
  }

  return __out
}

# The text of a block of n lines under <header>, with <trailing> blank
# lines after them.
function block_text(header, n, trailing) {
  if (n == 0) {
    return (header ~ /\+$/) ? block_ending(header, trailing - 1) : ""
  }
  if (header ~ /^>/) {
    return block_folded(n) block_ending(header, trailing)
  }

  return block_literal(n) block_ending(header, trailing)
}

# Writes the block scalar whose header the reader stands on, under a node
# indented by <parent>, as the str under <key>; the reader then stands on
# the first line past the block.
function write_block(key, header, parent, __n, __trailing) {
  Y_POS++
  __n = block_gather(parent)
  __trailing = block_trailing(__n)

  write_scalar(key, "str", wrap(block_text(header, __n - __trailing, __trailing)))
}
