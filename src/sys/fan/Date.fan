//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//

**
** Date represents a day in time independent of a timezone.
**
@Serializable { simple = true }
const final class Date
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Get today's Date using specified timezone.
  **
  static Date today(TimeZone tz := TimeZone.cur)

  **
  ** Make for the specified date values:
  **  - year:  no restriction (although only 1901-2099 maps to DateTime)
  **  - month: Month enumeration
  **  - day:   1-31
  **
  ** Throw ArgErr is any of the parameters are out of range.
  **
  static Date make(Int year, Month month, Int day)

  **
  ** Parse the string into a Date from the programmatic encoding
  ** defined by `toStr`.  If the string cannot be parsed into a valid
  ** Date and checked is false then return null, otherwise throw
  ** ParseErr.
  **
  static Date? fromStr(Str s, Bool checked := true)

  **
  ** Default value is "2000-01-01".
  **
  static const Date defVal

  **
  ** Private constructor.
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two dates are equal if have the same year, month, and day.
  **
  override Bool equals(Obj? that)

  **
  ** Return hash of year, month, and day.
  **
  override Int hash()

  **
  ** Compare based on year, month, and day.
  **
  override Int compare(Obj obj)

  **
  ** Return programmatic ISO 8601 string encoding formatted as follows:
  **   YYYY-MM-DD
  **   2009-01-10
  **
  ** Also `fromStr`, `toIso`, and `toLocale`.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the year as a number such as 2009.
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
  ** Get the day of the week for this date.
  **
  Weekday weekday()

  **
  ** Return the day of the year as a number between
  ** 1 and 365 (or 1 to 366 if a leap year).
  **
  Int dayOfYear()

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Format this date according to the specified pattern.  If
  ** pattern is null, then a localized default is used.  The
  ** pattern format is the same as `DateTime.toLocale`:
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
  **   'xyz'  Literal characters
  **
  Str toLocale(Str? pattern := null)

  **
  ** Parse a string into a Date using the given pattern.  If
  ** string is not a valid format then return null or raise ParseErr
  ** based on checked flag.  See `toLocale` for pattern syntax.
  **
  static Date? fromLocale(Str str, Str pattern, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse an ISO 8601 date.  If invalid format and checked is
  ** false return null, otherwise throw ParseErr.  The following
  ** format is supported:
  **   YYYY-MM-DD
  **
  ** Also see `toIso` and `fromStr`.
  **
  static Date? fromIso(Str s, Bool checked := true)

  **
  ** Format this instance according to ISO 8601 using the pattern:
  **   YYYY-MM-DD
  **
  ** Also see `fromIso` and `toStr`.
  **
  Str toIso()

//////////////////////////////////////////////////////////////////////////
// Past/Future
//////////////////////////////////////////////////////////////////////////

  **
  ** Add the specified number of days to this date to get a date in
  ** the future.  Throw ArgErr if 'days' parameter it not an even number
  ** of days.
  **
  ** Example:
  **   Date(2008, Month.feb, 28) + 2day  =>  2008-03-01
  **
  @Operator Date plus(Duration days)

  **
  ** Subtract the specified number of days to this date to get a date in
  ** the past.  Throw ArgErr if 'days' parameter it not an even number
  ** of days.
  **
  ** Example:
  **   Date(2008, Month.feb, 28) - 2day  =>  2008-02-26
  **
  @Operator Date minus(Duration days)

  **
  ** Return the delta between this and the given date.  The
  ** result is always an exact multiple of 24 hour days.
  **
  ** Example:
  **   Date(2009, Month.jan, 5) - Date(2009, Month.jan, 2)  =>  3day
  **
  @Operator Duration minusDate(Date days)

  **
  ** Get the first day of this Date's current month.
  **
  ** Example:
  **   Date("2009-10-28").firstOfMonth  =>  2009-10-01
  **
  Date firstOfMonth()

  **
  ** Get the last day of this Date's current month.
  **
  ** Example:
  **   Date("2009-10-28").lastOfMonth  =>  2009-10-31
  **
  Date lastOfMonth()

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  **
  ** Return is this date equal to `today` - 1day.
  **
  Bool isYesterday()

  **
  ** Return is this date equal to `today`.
  **
  Bool isToday()

  **
  ** Return is this date equal to `today` + 1day.
  **
  Bool isTomorrow()

  **
  ** Combine this Date with the given Time to return a DateTime.
  **
  DateTime toDateTime(Time t, TimeZone tz := TimeZone.cur)

  **
  ** Return a DateTime for the beginning of the this day at midnight.
  **
  DateTime midnight(TimeZone tz := TimeZone.cur)

  **
  ** Get this Date as a Fantom expression suitable for code generation.
  **
  Str toCode()

}