//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//

**
** DateTime represents an absolute instance in time.  Fantom time is
** normalized as nanosecond ticks since 1 Jan 2000 UTC with a
** supported range of 1901 to 2099.  Fantom time does not support
** leap seconds (same as Java and UNIX).  An instance of DateTime
** also models the date and time of an absolute instance against
** a specific `TimeZone`.
**
** Also see [docLang]`docLang::DateTime`.
**
@Serializable { simple = true }
const final class DateTime
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the current time using `TimeZone.cur`.  The tolerance
  ** parameter specifies that you are willing to use a cached DateTime
  ** instance as long as (now - cached <= tolerance).  If tolerance is null,
  ** then this method always creates a new DateTime instance.  Using
  ** tolerance can increase performance and save memory.  The
  ** tolerance default is 250ms.
  **
  ** If you are using time to calculate relative time periods,
  ** then use `Duration.now` instead.  Duration is more efficient
  ** and won't cause you grief when the system clock is modified.
  **
  static DateTime now(Duration? tolerance := 250ms)

  **
  ** Return the current time using `TimeZone.utc`.
  ** See `now` for a description of the tolerance parameter.
  **
  static DateTime nowUtc(Duration? tolerance := 250ms)

  **
  ** Return the current time as nanosecond ticks since 1 Jan 2000 UTC.
  **
  static Int nowTicks()

  **
  ** Return the current time as nanosecond ticks since 1 Jan 2000 UTC,
  ** but with the guarantee that every call returns a unique value for
  ** the lifetime of this VM.  Since most platforms don't actually support
  ** nanosecond resolution, the unused nanoseconds are used as a counter
  ** to ensure uniqueness.  However, bursts of calls may result in a
  ** drift from the actual system time.  For example if the platform's
  ** clock supports millisecond resolution, then calling this method
  ** more than one million time within a millisecond will introduce
  ** a millisecond drift (1,000,000ns in a ms).
  **
  static Int nowUnique()

  **
  ** Make for nanosecond ticks since 1 Jan 2000 UTC.  Throw
  ** ArgErr if ticks represent a year out of the range 1901
  ** to 2099.
  **
  static DateTime makeTicks(Int ticks, TimeZone tz := TimeZone.cur)

  **
  ** Make for the specified date and time values:
  **  - year:  1901-2099
  **  - month: Month enumeration
  **  - day:   1-31
  **  - hour:  0-23
  **  - min:   0-59
  **  - sec:   0-59
  **  - ns:    0-999_999_999
  **  - tz:    time zone used to map date/time to ns ticks
  **
  ** Throw ArgErr is any of the parameters are out of range.
  **
  static DateTime make(Int year, Month month, Int day, Int hour, Int min, Int sec := 0, Int ns := 0, TimeZone tz := TimeZone.cur)

  **
  ** Parse the string into a DateTime from the programmatic encoding
  ** defined by `toStr`.  If the string cannot be parsed into a valid
  ** DateTime and checked is false then return null, otherwise throw ParseErr.
  ** Also see `fromIso` and `fromHttpStr`.
  **
  static DateTime? fromStr(Str s, Bool checked := true)

  **
  ** Get the boot time of the Fantom VM with `TimeZone.cur`
  **
  static DateTime boot()

  **
  ** Default value is "2000-01-01T00:00:00Z UTC".
  **
  static const DateTime defVal

  **
  ** Private constructor.
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two times are equal if have identical nanosecond ticks.
  **
  override Bool equals(Obj? that)

  **
  ** Return nanosecond ticks for the hashcode.
  **
  override Int hash()

  **
  ** Compare based on nanosecond ticks.
  **
  override Int compare(Obj obj)

  **
  ** Return programmatic string encoding formatted as follows:
  **   "YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz zzzz"
  **
  ** See `toLocale` for the pattern legend.  The base of the
  ** string encoding conforms to ISO 8601 and XML Schema
  ** Part 2.  The Fantom format also appends the timezone name to
  ** avoid the ambiguities associated with interpretting the time
  ** zone offset.  Also see `toIso` and `toHttpStr`.
  **
  ** Examples:
  **   "2000-04-03T00:00:00.123Z UTC"
  **   "2006-10-31T01:02:03-05:00 New_York"
  **   "2009-03-10T11:33:20Z London"
  **   "2009-03-01T12:00:00+01:00 Amsterdam"
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return number of nanosecond ticks since 1 Jan 2000 UTC.
  ** Dates before this epoch will return a negative integer.
  **
  Int ticks()

  **
  ** Get the date component of this timestamp.
  **
  Date date()

  **
  ** Get the time component of this timestamp.
  **
  Time time()

  **
  ** Get the year as a number such as 2007.
  **
  Int year()

  **
  ** Get the month of this date.
  **
  Month month()

  **
  ** Get the day of the month as a number between 1 and 31.
  **
  Int day()

  **
  ** Get the hour of the time as a number between 0 and 23.
  **
  Int hour()

  **
  ** Get the minutes of the time as a number between 0 and 59.
  **
  Int min()

  **
  ** Get the whole seconds of the time as a number between 0 and 59.
  **
  Int sec()

  **
  ** Get the number of nanoseconds (the fraction of seconds) as
  ** a number between 0 and 999,999,999.
  **
  Int nanoSec()

  **
  ** Get the day of the week for this time.
  **
  Weekday weekday()

  **
  ** Get the time zone associated with this date time.
  **
  TimeZone tz()

  **
  ** Return if this time is within daylight savings time
  ** for its associated time zone.
  **
  Bool dst()

  **
  ** Get the time zone's abbreviation for this time.
  ** See `TimeZone.stdAbbr` and `TimeZone.dstAbbr`.
  **
  Str tzAbbr()

  **
  ** Return the day of the year as a number between
  ** 1 and 365 (or 1 to 366 if a leap year).
  **
  Int dayOfYear()

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Format this time according to the specified pattern.  If
  ** pattern is null, then a localized default is used.  Any
  ** ASCII letter in the pattern is interpreted as follows:
  **
  **   YY     Two digit year             07
  **   YYYY   Four digit year            2007
  **   M      One/two digit month        6, 11
  **   MM     Two digit month            06, 11
  **   MMM    Three letter abbr month    Jun, Nov
  **   MMMM   Full month                 June, November
  **   D      One/two digit day          5, 28
  **   DD     Two digit day              05, 28
  **   DDD    Day with suffix            1st, 2nd, 3rd, 24th
  **   WWW    Three letter abbr weekday  Tue
  **   WWWW   Full weekday               Tuesday
  **   h      One digit 24 hour (0-23)   3, 22
  **   hh     Two digit 24 hour (0-23)   03, 22
  **   k      One digit 12 hour (1-12)   3, 11
  **   kk     Two digit 12 hour (1-12)   03, 11
  **   m      One digit minutes (0-59)   4, 45
  **   mm     Two digit minutes (0-59)   04, 45
  **   s      One digit seconds (0-59)   4, 45
  **   ss     Two digit seconds (0-59)   04, 45
  **   SS     Optional seconds (only if non-zero)
  **   f*     Fractional secs trailing zeros
  **   F*     Fractional secs no trailing zeros
  **   a      Lower case a/p for am/pm   a, p
  **   aa     Lower case am/pm           am, pm
  **   A      Upper case A/P for am/pm   A, P
  **   AA     Upper case AM/PM           AM, PM
  **   z      Time zone offset           Z, +03:00 (ISO 8601, XML Schema)
  **   zzz    Time zone abbr             EST, EDT
  **   zzzz   Time zone name             New_York
  **   'xyz'  Literal characters
  **
  ** A symbol immediately preceding a "F" pattern with a no
  ** fraction to print is skipped.
  **
  ** Examples:
  **   YYYY-MM-DD'T'hh:mm:ss.FFFz  =>  2009-01-16T09:57:35.097-05:00
  **   DD MMM YYYY                 =>  06 Jan 2009
  **   DD/MMM/YY                   =>  06/Jan/09
  **   MMMM D, YYYY                =>  January 16, 2009
  **   hh:mm:ss.fff zzzz           =>  09:58:54.845 New_York
  **   k:mma                       =>  9:58a
  **   k:mmAA                      =>  9:58AM
  **
  Str toLocale(Str? pattern := null)

  **
  ** Parse a string into a DateTime using the given pattern.  If
  ** string is not a valid format then return null or raise ParseErr
  ** based on checked flag.  See `toLocale` for pattern syntax.
  **
  ** The timezone is inferred from the zone pattern, or else the
  ** given 'tz' parameter is used for the timezone.  If only a zone
  ** offset is available and it doesn't match the expected for the
  ** 'tz' parameter, then use a "GMT+/-" timezone.
  **
  static DateTime? fromLocale(Str str, Str pattern, TimeZone tz := TimeZone.cur, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Convert this DateTime to the specific timezone.  The absolute point
  ** time as ticks remains the same, but the date and time fields will
  ** be converted to represent the new time zone.  However if converting
  ** to or from `TimeZone.rel` then the resulting DateTime has the same
  ** day and time.  Also see `toUtc` and `toRel`.
  **
  ** Example:
  **   dt := DateTime("2010-06-03T10:30:00-04:00 New_York")
  **   dt.toUtc  =>  2010-06-03T14:30:00Z UTC
  **   dt.toRel  =>  2010-06-03T10:30:00Z Rel
  **
  DateTime toTimeZone(TimeZone tz)

  **
  ** Convenience for 'toTimeZone(TimeZone.utc)'.
  **
  DateTime toUtc()

  **
  ** Convenience for 'toTimeZone(TimeZone.rel)'.
  ** See [docLang]`docLang::DateTime#relTimeZone`.
  **
  DateTime toRel()

  **
  ** Return the delta between this and the given time.
  **
  ** Example:
  **   elapsed := DateTime.now - startTime
  **
  @Operator Duration minusDateTime(DateTime time)

  **
  ** Add a duration to compute a new time.  This method works
  ** off absolute time, so adding 1days means to add 24 hours to
  ** the ticks.  This might be a different time of day if on
  ** a DST boundry.  Use `Date.plus` for daily increments.
  **
  ** Example:
  **   nextHour := DateTime.now + 1hr
  **
  @Operator DateTime plus(Duration duration)

  **
  ** Subtract a duration to compute a new time.  This method works
  ** off absolute time, so subtracting 1days means to subtract 24
  ** hours from the ticks.  This might be a different time of day if
  ** on a DST boundry.  Use `Date.minus` for daily increments.
  **
  ** Example:
  **   prevHour := DateTime.now - 1hr
  **
  @Operator DateTime minus(Duration duration)

  **
  ** Return a new DateTime with this time's nanosecond ticks truncated
  ** according to the specified accuracy.  For example 'floor(1min)'
  ** will truncate this time to the minute such that seconds
  ** are 0.0.  This method is strictly based on absolute ticks,
  ** it does not take into account wall-time rollovers.
  **
  DateTime floor(Duration accuracy)

  **
  ** Return a DateTime for the beginning of the current day at midnight.
  **
  DateTime midnight()

  **
  ** Return if the time portion is "00:00:00".
  **
  Bool isMidnight()

  **
  ** Return if the specified year is a leap year.
  **
  static Bool isLeapYear(Int year)

  **
  ** This method computes the day of month (1-31) for a given
  ** weekday.  The pos parameter specifies the first, second,
  ** third, or fourth occurence of the weekday.  A negative pos
  ** is used to compute the last (or second to last, etc) weekday
  ** in the month.
  **
  ** Examples:
  **   // compute the second monday in Apr 2007
  **   weekdayInMonth(2007, Month.apr, Weekday.mon, 2)
  **
  **   // compute the last sunday in Oct 2007
  **   weekdayInMonth(2007, Month.oct, Weekday.sun, -1)
  **
  static Int weekdayInMonth(Int year, Month mon, Weekday weekday, Int pos)

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  **
  ** Create date for Java milliseconds since the epoch of 1 Jan 1970
  ** using the specified timezone (defaults to current).  If millis
  ** are less than or equal to zero then return null.
  **
  static DateTime? fromJava(Int millis, TimeZone tz := TimeZone.cur)

  **
  ** Get this date in Java milliseconds since the epoch of 1 Jan 1970.
  **
  Int toJava()

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse an ISO 8601 timestamp.  If invalid format and checked is
  ** false return null, otherwise throw ParseErr.  The following formats
  ** are supported:
  **   YYYY-MM-DD'T'hh:mm:ss[.FFFFFFFFF]
  **   YYYY-MM-DD'T'hh:mm:ss[.FFFFFFFFF]+HH:MM
  **   YYYY-MM-DD'T'hh:mm:ss[.FFFFFFFFF]-HH:MM
  **
  ** If a timezone offset is specified, then one the predefined "Etc/GMT+x"
  ** timezones are used for the result:
  **   DateTime("2009-01-15T12:00:00Z")       =>  2009-01-15T12:00:00Z UTC
  **   DateTime("2009-01-15T12:00:00-05:00")  =>  2009-01-15T12:00:00-05:00 GMT+5
  **
  ** Also see `toIso`, `fromStr`, and `fromHttpStr`.
  **
  static DateTime? fromIso(Str s, Bool checked := true)

  **
  ** Format this instance according to ISO 8601 using the pattern:
  **   YYYY-MM-DD'T'hh:mm:ss.FFFz
  **
  ** Also see `fromIso`, `toStr`, and `toHttpStr`.
  **
  Str toIso()

//////////////////////////////////////////////////////////////////////////
// HTTP
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse an HTTP date according to the RFC 2616 section 3.3.1.  If
  ** invalid format and checked is false return null, otherwise
  ** throw ParseErr.  The following date formats are supported:
  **
  **   Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
  **   Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
  **   Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format
  **
  static DateTime? fromHttpStr(Str s, Bool checked := true)

  **
  ** Format this time for use in an MIME or HTTP message
  ** according to RFC 2616 using the RFC 1123 format:
  **
  **   Sun, 06 Nov 1994 08:49:37 GMT
  **
  Str toHttpStr()

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this DateTime as a Fantom expression suitable for code generation.
  **
  Str toCode()


}