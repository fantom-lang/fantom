//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 05  Brian Frank  Creation
//

**
** Duration represents a relative duration of time with nanosecond precision.
**
const final class Duration
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current value of the system timer.  This method returns
  ** a relative time unrelated to system or wall-clock time.  Typically
  ** it is the number of nanosecond ticks which have elapsed since system
  ** startup.
  **
  static Duration now()

  **
  ** Create a Duration which represents the specified number of nanosecond ticks.
  **
  static Duration make(Int ticks)

  **
  ** Parse a Str into a Duration according to the Fan
  ** [literal format]`docLang::Literals#duration`.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.  The following suffixes
  ** are supported:
  **   ns:   nanoseconds  (x 1)
  **   ms:   milliseconds (x 1,000,000)
  **   sec:  seconds      (x 1,000,000,000)
  **   min:  minutes      (x 60,000,000,000)
  **   hr:   hours        (x 3,600,000,000,000)
  **   day:  days         (x 86,400,000,000,000)
  **
  ** Examples:
  **   Duration.fromStr("4ns")
  **   Duration.fromStr("100ms")
  **   Duration.fromStr("-0.5hr")
  **
  static Duration? fromStr(Str s, Bool checked := true)

  **
  ** Get the system timer at boot time of the Fan VM.
  **
  static Duration boot()

  **
  ** Get the duration which has elapsed since the
  ** Fan VM was booted which is 'now - boot'.
  **
  static Duration uptime()

  **
  ** Private constructor.
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if same number nanosecond ticks.
  **
  override Bool equals(Obj? obj)

  **
  ** Compare based on nanosecond ticks.
  **
  override Int compare(Obj obj)

  **
  ** Return ticks().
  **
  override Int hash()

  **
  ** Return string representation of the duration which is a valid
  ** duration literal format suitable for decoding via `fromStr`.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return number of nanosecond ticks.
  **
  Int ticks()

  **
  ** Negative of this.  Shortcut is -a.
  **
  Duration negate()

  **
  ** Multiply this with b.  Shortcut is a*b.
  **
  Duration mult(Float b)

  **
  ** Divide this by b.  Shortcut is a/b.
  **
  Duration div(Float b)

  **
  ** Add this with b.  Shortcut is a+b.
  **
  Duration plus(Duration b)

  **
  ** Subtract b from this.  Shortcut is a-b.
  **
  Duration minus(Duration b)

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a new Duration with this duration's nanosecond
  ** ticks truncated according to the specified accuracy.
  ** For example 'floor(1min)' will truncate this duration
  ** such that it's seconds are 0.0.
  **
  Duration floor(Duration accuracy)

  **
  ** Get this duration in milliseconds.  Any fractional
  ** milliseconds are truncated with a loss of precision.
  **
  Int toMillis()

  **
  ** Get this duration in seconds.  Any fractional
  ** seconds are truncated with a loss of precision.
  **
  Int toSec()

  **
  ** Get this duration in minutes.  Any fractional
  ** minutes are truncated with a loss of precision.
  Int toMin()

  **
  ** Get this duration in hours.  Any fractional
  ** hours are truncated with a loss of precision.
  **
  Int toHour()

  **
  ** Get this duration in 24 hour days.  Any fractional
  ** days are truncated with a loss of precision.
  **
  Int toDay()

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Return human friendly string representation.
  ** TODO: enhance this for pattern
  **
  Str toLocale()

}