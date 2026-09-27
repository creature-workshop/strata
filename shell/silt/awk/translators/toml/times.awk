# TOML's date-times as nodes of the reader's tree: an offset date-time as a
# time-rfc3339-utc, its offset folded into the clock and the date so the
# instant is spelled in UTC with nine fraction digits (ADR.23@strata); and a
# local date-time, a local date and a local time, which name no instant, as
# the map ADR.20 gives a spelling Strata has no primitive for, the format
# and the spelling alone. A field out of its range, a day its month has
# not, and a fraction past nine digits are refused. Loaded after
# awk/lines.awk and translators/write.awk, and text.awk and tree.awk beside
# this one.
#
#   time_node("1979-05-27T00:32:00.5-07:00")  ->  0."t":time-rfc3339-utc=1979-05-27T07:32:00.500000000Z
#   time_node("1979-05-27")                   ->  0."d":map
#                                                 1."format":str="toml"
#                                                 1."spelling":str="1979-05-27"

# Whether the token is a date, a time or a date-time as TOML spells one.
function is_toml_time(token) {
  return is_date(token) || is_clock(token) || is_date_time(token)
}

# Whether the token is a date, YYYY-MM-DD.
function is_date(token) {
  return token ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/
}

# Whether the token is a clock, HH:MM:SS with a fraction or not.
function is_clock(token) {
  return token ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9](\.[0-9]+)?$/
}

# Whether the token is a date and a clock, joined by T, t or a space, with
# an offset or not.
function is_date_time(token) {
  return token ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][Tt ][0-9][0-9]:[0-9][0-9]:[0-9][0-9](\.[0-9]+)?([Zz]|[-+][0-9][0-9]:[0-9][0-9])?$/
}

# Whether the token ends in an offset, Z or a signed HH:MM.
function has_offset(token) {
  return token ~ /([Zz]|[-+][0-9][0-9]:[0-9][0-9])$/
}

# The node of a date-time token: a time for an offset date-time, and the
# map that keeps the spelling for a local one, its fields checked.
function time_node(token) {
  if (is_date_time(token) && has_offset(token)) {
    return scalar_node("time-rfc3339-utc", utc_of(token))
  }

  check_local(token)
  return spelling_node(token, "", "")
}

# Checks the fields of a local date, clock or date-time.
function check_local(token) {
  if (is_date(token)) {
    check_date(substr(token, 1, 4) + 0, substr(token, 6, 2) + 0, substr(token, 9, 2) + 0)
  } else if (is_clock(token)) {
    check_clock(substr(token, 1, 2) + 0, substr(token, 4, 2) + 0, substr(token, 7, 2) + 0)
  } else {
    read_date_time(token)
    check_date(D_YEAR, D_MONTH, D_DAY)
    check_clock(D_HOUR, D_MINUTE, D_SECOND + 0)
  }
}

# Refuses a month or a day out of its range, the day's against its month.
function check_date(year, month, day) {
  if (month < 1 || month > 12) {
    refuse_toml("a month outside 01 to 12")
  }
  if (day < 1 || day > days_in(year, month)) {
    refuse_toml("a day its month has not")
  }
}

# Refuses an hour, a minute or a second out of its range; a second may be
# 60 where a leap second is one.
function check_clock(hour, minute, second) {
  if (hour > 23) {
    refuse_toml("an hour outside 00 to 23")
  }
  if (minute > 59) {
    refuse_toml("a minute outside 00 to 59")
  }
  if (second > 60) {
    refuse_toml("a second outside 00 to 60")
  }
}

# Whether the year is a leap year.
function is_leap(year) {
  return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

# How many days the month has in the year.
function days_in(year, month) {
  if (month == 2) {
    return is_leap(year) ? 29 : 28
  }
  if (month == 4 || month == 6 || month == 9 || month == 11) {
    return 30
  }

  return 31
}

# Reads a date-time token into D_YEAR, D_MONTH, D_DAY, D_HOUR and D_MINUTE
# as numbers, D_SECOND as its two digits, D_FRACTION as the digits after
# the point or nothing, and D_OFFSET as the text after them or nothing.
function read_date_time(token, __rest, __at) {
  D_YEAR = substr(token, 1, 4) + 0
  D_MONTH = substr(token, 6, 2) + 0
  D_DAY = substr(token, 9, 2) + 0
  D_HOUR = substr(token, 12, 2) + 0
  D_MINUTE = substr(token, 15, 2) + 0
  D_SECOND = substr(token, 18, 2)

  __rest = substr(token, 20)
  __at = match(__rest, /[Zz+-]/)
  D_OFFSET = (__at > 0) ? substr(__rest, __at) : ""
  D_FRACTION = (__rest ~ /^\./) ? substr(__rest, 2, ((__at > 0) ? __at : length(__rest) + 1) - 2) : ""
}

# The minutes an offset stands for, signed: none for Z, and its hours and
# minutes otherwise, each checked against its range.
function offset_minutes(offset, __hours, __minutes) {
  if (offset ~ /^[Zz]$/) {
    return 0
  }

  __hours = substr(offset, 2, 2) + 0
  __minutes = substr(offset, 5, 2) + 0
  if (__hours > 23 || __minutes > 59) {
    refuse_toml("an offset outside -23:59 to +23:59")
  }

  return ((offset ~ /^-/) ? -1 : 1) * (__hours * 60 + __minutes)
}

# The fraction padded to ADR.23's nine digits. Refuses a longer one, since
# nothing is rounded.
function nine_digits(fraction) {
  if (length(fraction) > 9) {
    refuse_toml("a fraction past nine digits")
  }

  return fraction substr("000000000", 1, 9 - length(fraction))
}

# Moves the date read one day on.
function next_day() {
  D_DAY++

  if (D_DAY > days_in(D_YEAR, D_MONTH)) {
    D_DAY = 1
    D_MONTH++
  }
  if (D_MONTH > 12) {
    D_MONTH = 1
    D_YEAR++
  }
}

# Moves the date read one day back.
function previous_day() {
  D_DAY--

  if (D_DAY < 1) {
    D_MONTH--
    if (D_MONTH < 1) {
      D_MONTH = 12
      D_YEAR--
    }
    D_DAY = days_in(D_YEAR, D_MONTH)
  }
}

# The minutes of the day the clock read stands at in UTC, the date read
# moved a day where the offset carries the clock over midnight.
function utc_minutes(__minutes) {
  __minutes = D_HOUR * 60 + D_MINUTE - offset_minutes(D_OFFSET)

  while (__minutes < 0) {
    __minutes = __minutes + 1440
    previous_day()
  }
  while (__minutes >= 1440) {
    __minutes = __minutes - 1440
    next_day()
  }

  return __minutes
}

# The instant an offset date-time names, spelled as ADR.23 has it: the
# offset folded into the clock and the date, T and Z in capitals, and the
# fraction padded to nine digits.
function utc_of(token, __minutes) {
  read_date_time(token)
  check_date(D_YEAR, D_MONTH, D_DAY)
  check_clock(D_HOUR, D_MINUTE, D_SECOND + 0)

  __minutes = utc_minutes()
  if (D_YEAR < 0 || D_YEAR > 9999) {
    refuse_toml("a date outside the years RFC 3339 spells")
  }

  return sprintf("%04d-%02d-%02dT%02d:%02d:%s.%sZ", D_YEAR, D_MONTH, D_DAY, int(__minutes / 60), __minutes % 60, D_SECOND, nine_digits(D_FRACTION))
}
