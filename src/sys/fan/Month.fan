//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Brian Frank  Creation
//

**
** Enum for twelve months of the year.
**
enum class Month
{
  ** January
  jan,
  ** February
  feb,
  ** March
  mar,
  ** April
  apr,
  ** May
  may,
  ** June
  jun,
  ** July
  jul,
  ** August
  aug,
  ** September
  sep,
  ** October
  oct,
  ** November
  nov,
  ** December
  dec

  **
  ** Return the month after this month.
  **
  @Operator Month increment()

  **
  ** Return the month before this month.
  **
  @Operator Month decrement()

  **
  ** Return the number of days in this month for the specified year.
  **
  Int numDays(Int year)

  **
  ** Return the month as a localized string according to the
  ** specified pattern.  The pattern rules are a subset of the
  ** `DateTime.toLocale`:
  **
  **    M      One/two digit month        6, 11
  **    MM     Two digit month            06, 11
  **    MMM    Three letter abbr month    Jun, Nov
  **    MMMM   Full month name            June, November
  **
  ** If pattern is null it defaults to "MMM".  Also see `localeAbbr`
  ** and `localeFull`.
  **
  Str toLocale(Str? pattern := null)

  **
  ** Get the abbreviated name for the current locale.
  ** Configured by the 'sys::<name>Abbr' localized property.
  **
  Str localeAbbr()

  **
  ** Get the full name for the current locale.
  ** Configured by the 'sys::<name>Full' localized property.
  **
  Str localeFull()

}