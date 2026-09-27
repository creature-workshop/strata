# A YAML block scalar, the lines under a "|" or a ">", written into the SILT
# writer as one str. A literal block keeps its line breaks; a folded one
# joins a line to the next with a space, a blank line standing for a line
# break and a line indented further kept on its own. The "-" and "+" after
# the mark strip or keep the line breaks at the end, and a digit there says
# how far past its parent the block is indented, which a block whose first
# line starts with a space needs. Loaded after translators/write.awk and
# lines.awk beside this one.
#
#   key: |          key: >-        key: |2-
#     a               a               text
#     b               b           -> " text"
#   -> "a\nb\n"     -> "a b"

# Whether the text is the mark that opens a block scalar: the bar or the
# angle, then a chomping sign and an indentation digit in either order.
function is_block_header(text) {
  return text ~ /^[|>]([-+]?[1-9]?|[1-9][-+])$/
}

# The indentation digit of a block header, or 0 when it has none.
function header_indent(header) {
  if (header ~ /[1-9]/) {
    return substr(header, match(header, /[1-9]/), 1) + 0
  }

  return 0
}

# Whether raw line i belongs to a block under a node indented by <parent>:
# it holds nothing, or it is indented further.
function block_holds(i, parent) {
  return Y_RAW[i] ~ /^ *$/ || indent_of(Y_RAW[i]) > parent
}

# Gathers the block's lines into BLOCK[1..n], the block's own indentation
# off, and steps past them. Returns n. The block is indented by <indent>
# when the header says so, and otherwise as far as its first line that
# holds something.
function block_gather(parent, indent, __n, __i, __indent) {
  __indent = (indent > 0) ? indent : -1
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
  if (index(header, "-") > 0) {
    return ""
  }

  __out = "\n"
  while (index(header, "+") > 0 && trailing-- > 0) {
    __out = __out "\n"
  }

  return __out
}

# The text of a block of n lines under <header>, with <trailing> blank
# lines after them.
function block_text(header, n, trailing) {
  if (n == 0) {
    return (index(header, "+") > 0) ? block_ending(header, trailing - 1) : ""
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
  __n = block_gather(parent, (header_indent(header) > 0) ? parent + header_indent(header) : 0)
  __trailing = block_trailing(__n)

  write_scalar(key, "str", wrap(block_text(header, __n - __trailing, __trailing)))
}
