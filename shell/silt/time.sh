#!/bin/sh

: <<'MODULE'
silt__time and silt__now: a time document, from text carrying an offset or
from the clock.

A time is an instant in UTC spelled exactly one way (ADR.23@strata), a
capital T and Z and nine fraction digits, so text order is time order and
two writers spell one instant in the same thirty bytes. The reading, the
checks and the offset's conversion run in the shell's own arithmetic, with
no process; only the clock starts one, date.
MODULE

: <<'PUB_FUN'
Builds a time document from an RFC 3339 date-time carrying an offset: the
offset folded into the clock and the date, T and Z in capitals, and the
fraction padded to nine digits. Refuses text that is no date-time, one with
no offset, which names no instant, a field outside its range, a day its
month has not, and a fraction past nine digits, since nothing is rounded.

  silt__time doc '2026-09-22T08:10:04.5+02:00'
    ->  doc='0.:time-rfc3339-utc=2026-09-22T06:10:04.500000000Z'

args:
  $1  The name of the variable to answer in
  $2  The date-time, T, t or a space between its date and its clock
PUB_FUN
silt__time() {
  __silt__out "$1" || return 1
  __silt__time__out="$__silt__OUT"

  __silt__time__read "$2" || return 1
  __silt__time__check_date "$2" || return 1
  __silt__time__check_clock "$2" || return 1
  __silt__time__to_utc "$2" || return 1
  __silt__time__spell

  __silt__ANSWER="0.:time-rfc3339-utc=$__silt__time__SPELLING"
  __silt__OUT="$__silt__time__out"
  __silt__answer
}

: <<'PUB_FUN'
Builds a time document from the clock, now, starting one date. A date that
spells no fraction, as BSD's does not, gives nine zeros.

  silt__now doc   ->  doc='0.:time-rfc3339-utc=2026-09-27T14:03:11.402118337Z'

args:
  $1  The name of the variable to answer in
PUB_FUN
silt__now() {
  __silt__out "$1" || return 1
  __silt__now__out="$__silt__OUT"

  if ! __silt__now__clock="$(date -u '+%Y-%m-%dT%H:%M:%S.%NZ')"; then
    __silt__fail "the clock could not be read: date failed"
    return 1
  fi

  case "${__silt__now__clock##*.}" in
    # structs-lint: allow -- a fraction's spelling, digits or a date's unexpanded %N; SILT sits beneath structs
    *[!0-9]*Z) __silt__now__clock="${__silt__now__clock%.*}Z" ;;
  esac

  silt__time "$__silt__now__out" "$__silt__now__clock"
}

: <<'FUN'
Reads a date-time into the registers, refusing any other text: the fields
as numbers in __silt__time__YEAR, MONTH, DAY, HOUR and MINUTE, the second as
its two digits in __silt__time__SECOND, the fraction's digits or nothing in
__silt__time__FRACTION, and the offset in __silt__time__OFFSET.

  __silt__time__read '2026-09-22T08:10:04.5+02:00'
    ->  YEAR 2026  MONTH 9  DAY 22  HOUR 8  MINUTE 10  SECOND 04
        FRACTION 5  OFFSET +02:00

args:
  $1  The text
FUN
__silt__time__read() {
  case "$1" in
    # structs-lint: allow -- RFC 3339's date and clock, digit for digit; SILT sits beneath structs
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][Tt\ ][0-9][0-9]:[0-9][0-9]:[0-9][0-9]*) ;;
    *)
      __silt__fail "not an RFC 3339 date-time: $1"
      return 1
      ;;
  esac

  __silt__time__read_fields "$1"
  __silt__time__read_rest "$1" "${1#???????????????????}"
}


: <<'FUN'
Reads the fields of a date-time whose date and clock are already known to
be digits where RFC 3339 puts them into the registers __silt__time__read
names.

args:
  $1  The text
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
Reads what follows a date-time's seconds, its fraction and its offset, into
__silt__time__FRACTION and __silt__time__OFFSET, and the offset's signed
minutes into __silt__time__OFFSET_MINUTES. Refuses anything between the
seconds and the offset but a point and digits, a fraction past nine digits,
and an offset missing or misspelled.

  __silt__time__read_rest '…' '.5+02:00'  ->  FRACTION 5  OFFSET +02:00  OFFSET_MINUTES 120

args:
  $1  The whole text, for the refusal
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
Refuses a fraction that is not a point and digits, or runs past the nine
digits ADR.23@strata allows; nothing is rounded.

args:
  $1  The whole text, for the refusal
  $2  The text between the seconds and the offset, the point included
FUN
__silt__time__check_fraction() {
  case "$2" in
    # structs-lint: allow -- a fraction's spelling, a point and digits; SILT sits beneath structs
    . | .*[!0-9]* | [!.]*)
      __silt__fail "not an RFC 3339 date-time: $1"
      return 1
      ;;
  esac

  if [ "${#__silt__time__FRACTION}" -gt 9 ]; then
    __silt__fail "a fraction past nine digits: $1"
    return 1
  fi
}

: <<'FUN'
Refuses an offset that is missing, since a date-time without one names no
instant, or spelled other than Z or a signed HH:MM, and reads the rest into
__silt__time__OFFSET_MINUTES.

args:
  $1  The whole text, for the refusal
FUN
__silt__time__check_offset() {
  case "$__silt__time__OFFSET" in
    Z | z) __silt__time__OFFSET_MINUTES=0 ;;
    # structs-lint: allow -- an offset's spelling, a sign and HH:MM; SILT sits beneath structs
    [+-][0-9][0-9]:[0-9][0-9]) __silt__time__offset_minutes "$1" ;;
    '') __silt__fail "no offset, so no instant: $1" ;;
    *) __silt__fail "not an RFC 3339 date-time: $1" ;;
  esac
}

: <<'FUN'
Reads a signed HH:MM offset into __silt__time__OFFSET_MINUTES, the minutes
it stands ahead of UTC. Refuses hours past 23 or minutes past 59.

  __silt__time__offset_minutes '…'   (OFFSET -07:30)  ->  OFFSET_MINUTES -450

args:
  $1  The whole text, for the refusal
FUN
__silt__time__offset_minutes() {
  __silt__time__offset_minutes__hours="${__silt__time__OFFSET#?}"

  __silt__time__number "${__silt__time__offset_minutes__hours%:*}"
  __silt__time__offset_minutes__hours="$__silt__time__NUMBER"
  __silt__time__number "${__silt__time__OFFSET#*:}"

  if [ "$__silt__time__offset_minutes__hours" -gt 23 ] || [ "$__silt__time__NUMBER" -gt 59 ]; then
    __silt__fail "an offset outside -23:59 to +23:59: $1"
    return 1
  fi

  __silt__time__OFFSET_MINUTES=$((__silt__time__offset_minutes__hours * 60 + __silt__time__NUMBER))
  if [ "${__silt__time__OFFSET%"${__silt__time__OFFSET#?}"}" = - ]; then
    __silt__time__OFFSET_MINUTES=$((0 - __silt__time__OFFSET_MINUTES))
  fi
}

: <<'FUN'
Reads digits as a number the shell's arithmetic takes into
__silt__time__NUMBER: its leading zeros dropped, which would otherwise make
it octal, and 0 for zeros alone.

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
Refuses a month outside 01 to 12, and a day its month has not.

args:
  $1  The whole text, for the refusal
FUN
__silt__time__check_date() {
  if [ "$__silt__time__MONTH" -lt 1 ] || [ "$__silt__time__MONTH" -gt 12 ]; then
    __silt__fail "a month outside 01 to 12: $1"
    return 1
  fi

  __silt__time__days_in "$__silt__time__YEAR" "$__silt__time__MONTH"
  if [ "$__silt__time__DAY" -lt 1 ] || [ "$__silt__time__DAY" -gt "$__silt__time__DAYS" ]; then
    __silt__fail "a day its month has not: $1"
    return 1
  fi
}

: <<'FUN'
Refuses an hour past 23, a minute past 59, or a second past 60, which is a
leap second's.

args:
  $1  The whole text, for the refusal
FUN
__silt__time__check_clock() {
  __silt__time__number "$__silt__time__SECOND"

  if [ "$__silt__time__HOUR" -gt 23 ]; then
    __silt__fail "an hour outside 00 to 23: $1"
    return 1
  fi
  if [ "$__silt__time__MINUTE" -gt 59 ]; then
    __silt__fail "a minute outside 00 to 59: $1"
    return 1
  fi
  if [ "$__silt__time__NUMBER" -gt 60 ]; then
    __silt__fail "a second outside 00 to 60: $1"
    return 1
  fi
}

: <<'FUN'
Reads how many days a month has in a year into __silt__time__DAYS.

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
Folds the offset into the clock and the date read, so they stand in UTC,
moving the date a day where the offset carries the clock over midnight.
Refuses an instant that lands outside the years 0000 to 9999, which
RFC 3339 cannot spell.

  2026-01-01T01:30:00+02:00  ->  2025-12-31T23:30

args:
  $1  The whole text, for the refusal
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
    __silt__fail "a date outside the years RFC 3339 spells: $1"
    return 1
  fi
}

: <<'FUN'
Moves the date read one day on.
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
Moves the date read one day back.
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
Spells the instant read into __silt__time__SPELLING as ADR.23@strata has
it: every field at its width, T and Z in capitals, and the fraction padded
on the right to nine digits.

  YEAR 2026  MONTH 9  DAY 22  HOUR 6  MINUTE 10  SECOND 04  FRACTION 5
    ->  SPELLING 2026-09-22T06:10:04.500000000Z
FUN
__silt__time__spell() {
  __silt__time__pad 4 "$__silt__time__YEAR"
  __silt__time__SPELLING="$__silt__time__PADDED-"
  __silt__time__pad 2 "$__silt__time__MONTH"
  __silt__time__SPELLING="$__silt__time__SPELLING$__silt__time__PADDED-"
  __silt__time__pad 2 "$__silt__time__DAY"
  __silt__time__SPELLING="${__silt__time__SPELLING}${__silt__time__PADDED}T"
  __silt__time__pad 2 "$__silt__time__HOUR"
  __silt__time__SPELLING="$__silt__time__SPELLING$__silt__time__PADDED:"
  __silt__time__pad 2 "$__silt__time__MINUTE"
  __silt__time__SPELLING="$__silt__time__SPELLING$__silt__time__PADDED:$__silt__time__SECOND."

  __silt__time__spell__fraction="$__silt__time__FRACTION"
  while [ "${#__silt__time__spell__fraction}" -lt 9 ]; do
    __silt__time__spell__fraction="${__silt__time__spell__fraction}0"
  done

  __silt__time__SPELLING="${__silt__time__SPELLING}${__silt__time__spell__fraction}Z"
}

: <<'FUN'
Reads a number into __silt__time__PADDED, zeros in front to the width.

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
