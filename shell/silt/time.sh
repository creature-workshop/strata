#!/bin/sh

: <<'MODULE'
silt__time and silt__now: create a time document from a date-time string or
from the system clock.

A time is always written in UTC in one fixed format (ADR.23@strata):
YYYY-MM-DDTHH:MM:SS.nnnnnnnnnZ, with exactly nine fractional digits. Because
the format is fixed, sorting times as strings sorts them chronologically.

Parsing, validation and UTC conversion use shell arithmetic only and start
no process. silt__now starts one process, date, to read the clock.
MODULE

: <<'PUB_FUN'
Creates a time document from an RFC 3339 date-time string. The string must
include a UTC offset (Z or +HH:MM). The result is converted to UTC, and the
fractional seconds are padded with zeros to nine digits.

Fails if the string is not a valid date-time, has no offset, has a field
that is out of range, names a day that does not exist, or has more than
nine fractional digits. Values are never rounded.

  silt__time doc '2026-09-22T08:10:04.5+02:00'
    ->  doc='0.:time-rfc3339-utc=2026-09-22T06:10:04.500000000Z'

args:
  $1  Name of the variable that receives the result
  $2  The date-time string. The date and time may be separated by T, t or
      a space.
PUB_FUN
silt__time() {
  __silt__out "$1" || return 1
  __silt__time__out="$__silt__OUT"

  __silt__time__read "$2" || return 1
  __silt__time__check_date "$2" || return 1
  __silt__time__check_clock "$2" || return 1
  __silt__time__to_utc "$2" || return 1
  __silt__time__format

  __silt__ANSWER="0.:time-rfc3339-utc=$__silt__time__FORMATTED"
  __silt__OUT="$__silt__time__out"
  __silt__answer
}

: <<'PUB_FUN'
Creates a time document for the current time. Runs the date command once.
If date does not support fractional seconds (BSD date does not), the
fraction is nine zeros.

  silt__now doc   ->  doc='0.:time-rfc3339-utc=2026-09-27T14:03:11.402118337Z'

args:
  $1  Name of the variable that receives the result
PUB_FUN
silt__now() {
  __silt__out "$1" || return 1
  __silt__now__out="$__silt__OUT"

  if ! __silt__now__clock="$(date -u '+%Y-%m-%dT%H:%M:%S.%NZ')"; then
    __silt__fail "could not read the current time: the date command failed"
    return 1
  fi

  case "${__silt__now__clock##*.}" in
    # structs-lint: allow -- matches a fraction that is not all digits, which is what date prints when it does not support %N
    *[!0-9]*Z) __silt__now__clock="${__silt__now__clock%.*}Z" ;;
  esac

  silt__time "$__silt__now__out" "$__silt__now__clock"
}

: <<'FUN'
Parses a date-time string into the __silt__time__ variables: YEAR, MONTH,
DAY, HOUR and MINUTE as numbers, SECOND as two digits, FRACTION as the
fractional digits (or empty), and OFFSET as the offset text. Fails if the
string does not start with a date and time in RFC 3339 format.

  __silt__time__read '2026-09-22T08:10:04.5+02:00'
    ->  YEAR 2026  MONTH 9  DAY 22  HOUR 8  MINUTE 10  SECOND 04
        FRACTION 5  OFFSET +02:00

args:
  $1  The date-time string
FUN
__silt__time__read() {
  case "$1" in
    # structs-lint: allow -- matches the fixed positions of an RFC 3339 date and time
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][Tt\ ][0-9][0-9]:[0-9][0-9]:[0-9][0-9]*) ;;
    *)
      __silt__fail "not a valid RFC 3339 date-time: $1"
      return 1
      ;;
  esac

  __silt__time__read_fields "$1"
  __silt__time__read_rest "$1" "${1#???????????????????}"
}


: <<'FUN'
Extracts the date and time fields from a date-time string into the
variables listed under __silt__time__read. The caller has already checked
that the string has digits in the right positions.

args:
  $1  The date-time string
FUN
__silt__time__read_fields() {
  __silt__time__read_fields__date="${1%%[Tt ]*}"
  __silt__time__read_fields__clock="${1#???????????}"
  __silt__time__read_fields__month="${__silt__time__read_fields__date#*-}"
  __silt__time__read_fields__minute="${__silt__time__read_fields__clock#*:}"

  __silt__time__number "${__silt__time__read_fields__date%%-*}"
  __silt__time__YEAR="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__read_fields__month%%-*}"
  __silt__time__MONTH="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__read_fields__date##*-}"
  __silt__time__DAY="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__read_fields__clock%%:*}"
  __silt__time__HOUR="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__read_fields__minute%%:*}"
  __silt__time__MINUTE="$__silt__time__NUMBER"
  __silt__time__SECOND="${__silt__time__read_fields__minute#*:}"
  __silt__time__SECOND="${__silt__time__SECOND%"${__silt__time__SECOND#??}"}"
}

: <<'FUN'
Parses the part of a date-time string that follows the seconds: the
optional fractional seconds and the offset. Sets __silt__time__FRACTION,
__silt__time__OFFSET and __silt__time__OFFSET_MINUTES (the offset in
minutes, negative for offsets west of UTC). Fails if that part contains
anything other than a fraction and an offset, if the fraction has more than
nine digits, or if the offset is missing or malformed.

  __silt__time__read_rest '...' '.5+02:00'  ->  FRACTION 5  OFFSET +02:00  OFFSET_MINUTES 120

args:
  $1  The whole date-time string, used in error messages
  $2  The text after the seconds
FUN
__silt__time__read_rest() {
  __silt__time__read_rest__point="${2%%[Zz+-]*}"
  __silt__time__FRACTION="${__silt__time__read_rest__point#.}"
  __silt__time__OFFSET="${2#"$__silt__time__read_rest__point"}"

  __silt__time__check_fraction "$1" "$__silt__time__read_rest__point" || return 1
  __silt__time__check_offset "$1"
}

: <<'FUN'
Fails if the fractional seconds are not a dot followed by digits, or if
there are more than nine digits (ADR.23@strata). Values are never rounded.

args:
  $1  The whole date-time string, used in error messages
  $2  The text between the seconds and the offset, including the dot
FUN
__silt__time__check_fraction() {
  case "$2" in
    # structs-lint: allow -- matches anything that is not a dot followed by digits
    . | .*[!0-9]* | [!.]*)
      __silt__fail "not a valid RFC 3339 date-time: $1"
      return 1
      ;;
  esac

  if [ "${#__silt__time__FRACTION}" -gt 9 ]; then
    __silt__fail "fractional seconds have more than nine digits: $1"
    return 1
  fi
}

: <<'FUN'
Validates the offset in __silt__time__OFFSET and sets
__silt__time__OFFSET_MINUTES. Fails if the offset is missing, because a
date-time without an offset does not identify a point in time, or if it is
not Z or a signed HH:MM.

args:
  $1  The whole date-time string, used in error messages
FUN
__silt__time__check_offset() {
  case "$__silt__time__OFFSET" in
    Z | z) __silt__time__OFFSET_MINUTES=0 ;;
    # structs-lint: allow -- matches a signed HH:MM offset
    [+-][0-9][0-9]:[0-9][0-9]) __silt__time__offset_minutes "$1" ;;
    '') __silt__fail "date-time has no UTC offset: $1" ;;
    *) __silt__fail "not a valid RFC 3339 date-time: $1" ;;
  esac
}

: <<'FUN'
Converts a signed HH:MM offset to minutes and stores the result in
__silt__time__OFFSET_MINUTES. Fails if the hours are above 23 or the
minutes are above 59.

  __silt__time__offset_minutes '...'   (OFFSET -07:30)  ->  OFFSET_MINUTES -450

args:
  $1  The whole date-time string, used in error messages
FUN
__silt__time__offset_minutes() {
  __silt__time__offset_minutes__hours="${__silt__time__OFFSET#?}"

  __silt__time__number "${__silt__time__offset_minutes__hours%:*}"
  __silt__time__offset_minutes__hours="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__OFFSET#*:}"

  if [ "$__silt__time__offset_minutes__hours" -gt 23 ] || [ "$__silt__time__NUMBER" -gt 59 ]; then
    __silt__fail "UTC offset is out of range (-23:59 to +23:59): $1"
    return 1
  fi

  __silt__time__OFFSET_MINUTES=$((__silt__time__offset_minutes__hours * 60 + __silt__time__NUMBER))
  if [ "${__silt__time__OFFSET%"${__silt__time__OFFSET#?}"}" = - ]; then
    __silt__time__OFFSET_MINUTES=$((0 - __silt__time__OFFSET_MINUTES))
  fi
}

: <<'FUN'
Converts a string of digits to a number that shell arithmetic can use, and
stores it in __silt__time__NUMBER. Leading zeros are removed because the
shell would otherwise read the number as octal.

  __silt__time__number 08    ->  NUMBER 8
  __silt__time__number 0000  ->  NUMBER 0

args:
  $1  The digits
FUN
__silt__time__number() {
  __silt__time__NUMBER="${1#"${1%%[!0]*}"}"
  __silt__time__NUMBER="${__silt__time__NUMBER:-0}"
}

: <<'FUN'
Fails if the month is not between 1 and 12, or if the day does not exist
in that month and year.

args:
  $1  The whole date-time string, used in error messages
FUN
__silt__time__check_date() {
  if [ "$__silt__time__MONTH" -lt 1 ] || [ "$__silt__time__MONTH" -gt 12 ]; then
    __silt__fail "month is out of range (01 to 12): $1"
    return 1
  fi

  __silt__time__days_in "$__silt__time__YEAR" "$__silt__time__MONTH"
  if [ "$__silt__time__DAY" -lt 1 ] || [ "$__silt__time__DAY" -gt "$__silt__time__DAYS" ]; then
    __silt__fail "day does not exist in that month: $1"
    return 1
  fi
}

: <<'FUN'
Fails if the hour is above 23, the minute is above 59, or the second is
above 60. A second of 60 is allowed because of leap seconds.

args:
  $1  The whole date-time string, used in error messages
FUN
__silt__time__check_clock() {
  __silt__time__number "$__silt__time__SECOND"

  if [ "$__silt__time__HOUR" -gt 23 ]; then
    __silt__fail "hour is out of range (00 to 23): $1"
    return 1
  fi
  if [ "$__silt__time__MINUTE" -gt 59 ]; then
    __silt__fail "minute is out of range (00 to 59): $1"
    return 1
  fi
  if [ "$__silt__time__NUMBER" -gt 60 ]; then
    __silt__fail "second is out of range (00 to 60): $1"
    return 1
  fi
}

: <<'FUN'
Stores the number of days in the given month in __silt__time__DAYS, taking
leap years into account.

  __silt__time__days_in 2024 2  ->  DAYS 29
  __silt__time__days_in 1900 2  ->  DAYS 28

args:
  $1  The year
  $2  The month, 1 to 12
FUN
__silt__time__days_in() {
  case "$2" in
    2) __silt__time__DAYS=$((28 + (($1 % 4 == 0 && $1 % 100 != 0) || $1 % 400 == 0))) ;;
    4 | 6 | 9 | 11) __silt__time__DAYS=30 ;;
    *) __silt__time__DAYS=31 ;;
  esac
}

: <<'FUN'
Converts the parsed date and time to UTC by subtracting the offset. If
that crosses midnight, the date moves forward or back by one day. Fails if
the resulting year is outside 0000 to 9999, which RFC 3339 cannot
represent.

  2026-01-01T01:30:00+02:00  ->  2025-12-31T23:30

args:
  $1  The whole date-time string, used in error messages
FUN
__silt__time__to_utc() {
  __silt__time__to_utc__minutes=$((__silt__time__HOUR * 60 + __silt__time__MINUTE - __silt__time__OFFSET_MINUTES))

  if [ "$__silt__time__to_utc__minutes" -lt 0 ]; then
    __silt__time__to_utc__minutes=$((__silt__time__to_utc__minutes + 1440))
    __silt__time__previous_day
  fi
  if [ "$__silt__time__to_utc__minutes" -ge 1440 ]; then
    __silt__time__to_utc__minutes=$((__silt__time__to_utc__minutes - 1440))
    __silt__time__next_day
  fi

  __silt__time__HOUR=$((__silt__time__to_utc__minutes / 60))
  __silt__time__MINUTE=$((__silt__time__to_utc__minutes % 60))

  if [ "$__silt__time__YEAR" -lt 0 ] || [ "$__silt__time__YEAR" -gt 9999 ]; then
    __silt__fail "year is out of range (0000 to 9999) after converting to UTC: $1"
    return 1
  fi
}

: <<'FUN'
Moves the parsed date forward by one day.
FUN
__silt__time__next_day() {
  __silt__time__days_in "$__silt__time__YEAR" "$__silt__time__MONTH"
  __silt__time__DAY=$((__silt__time__DAY + 1))

  if [ "$__silt__time__DAY" -gt "$__silt__time__DAYS" ]; then
    __silt__time__DAY=1
    __silt__time__MONTH=$((__silt__time__MONTH + 1))
  fi
  if [ "$__silt__time__MONTH" -gt 12 ]; then
    __silt__time__MONTH=1
    __silt__time__YEAR=$((__silt__time__YEAR + 1))
  fi
}

: <<'FUN'
Moves the parsed date back by one day.
FUN
__silt__time__previous_day() {
  __silt__time__DAY=$((__silt__time__DAY - 1))
  if [ "$__silt__time__DAY" -ge 1 ]; then
    return
  fi

  __silt__time__MONTH=$((__silt__time__MONTH - 1))
  if [ "$__silt__time__MONTH" -lt 1 ]; then
    __silt__time__MONTH=12
    __silt__time__YEAR=$((__silt__time__YEAR - 1))
  fi

  __silt__time__days_in "$__silt__time__YEAR" "$__silt__time__MONTH"
  __silt__time__DAY="$__silt__time__DAYS"
}

: <<'FUN'
Formats the parsed date and time in the fixed format of ADR.23@strata and
stores the result in __silt__time__FORMATTED. Every field is zero-padded
to its width, and the fraction is padded on the right to nine digits.

  YEAR 2026  MONTH 9  DAY 22  HOUR 6  MINUTE 10  SECOND 04  FRACTION 5
    ->  FORMATTED 2026-09-22T06:10:04.500000000Z
FUN
__silt__time__format() {
  __silt__time__pad 4 "$__silt__time__YEAR"
  __silt__time__FORMATTED="$__silt__time__PADDED-"
  __silt__time__pad 2 "$__silt__time__MONTH"
  __silt__time__FORMATTED="$__silt__time__FORMATTED$__silt__time__PADDED-"
  __silt__time__pad 2 "$__silt__time__DAY"
  __silt__time__FORMATTED="${__silt__time__FORMATTED}${__silt__time__PADDED}T"
  __silt__time__pad 2 "$__silt__time__HOUR"
  __silt__time__FORMATTED="$__silt__time__FORMATTED$__silt__time__PADDED:"
  __silt__time__pad 2 "$__silt__time__MINUTE"
  __silt__time__FORMATTED="$__silt__time__FORMATTED$__silt__time__PADDED:$__silt__time__SECOND."

  __silt__time__format__fraction="$__silt__time__FRACTION"
  while [ "${#__silt__time__format__fraction}" -lt 9 ]; do
    __silt__time__format__fraction="${__silt__time__format__fraction}0"
  done

  __silt__time__FORMATTED="${__silt__time__FORMATTED}${__silt__time__format__fraction}Z"
}

: <<'FUN'
Pads a number with leading zeros to the given width and stores the result
in __silt__time__PADDED.

  __silt__time__pad 4 99  ->  PADDED 0099

args:
  $1  The width
  $2  The number
FUN
__silt__time__pad() {
  __silt__time__PADDED="$2"

  while [ "${#__silt__time__PADDED}" -lt "$1" ]; do
    __silt__time__PADDED="0$__silt__time__PADDED"
  done
}
