//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//

**
** DateTimeTest
**
class DateTimeTest : Test
{

  const Month jan := Month.jan
  const Month feb := Month.feb
  const Month mar := Month.mar
  const Month apr := Month.apr
  const Month may := Month.may
  const Month jun := Month.jun
  const Month jul := Month.jul
  const Month aug := Month.aug
  const Month sep := Month.sep
  const Month oct := Month.oct
  const Month nov := Month.nov
  const Month dec := Month.dec

  const Weekday sun := Weekday.sun
  const Weekday mon := Weekday.mon
  const Weekday tue := Weekday.tue
  const Weekday wed := Weekday.wed
  const Weekday thu := Weekday.thu
  const Weekday fri := Weekday.fri
  const Weekday sat := Weekday.sat

  const TimeZone utc     := TimeZone.utc
  const TimeZone ny      := TimeZone.fromStr("America/New_York")
  const TimeZone la      := TimeZone.fromStr("America/Los_Angeles")
  const TimeZone uk      := TimeZone.fromStr("Europe/London")
  const TimeZone nl      := TimeZone.fromStr("Europe/Amsterdam")
  const TimeZone kiev    := TimeZone.fromStr("Europe/Kiev")
  const TimeZone brazil  := TimeZone.fromStr("America/Sao_Paulo")
  const TimeZone aust    := TimeZone.fromStr("Australia/Sydney")
  const TimeZone riga    := TimeZone.fromStr("Europe/Riga")
  const TimeZone jeru    := TimeZone.fromStr("Asia/Jerusalem")
  const TimeZone stJohn  := TimeZone.fromStr("America/St_Johns")
  const TimeZone godthab := TimeZone.fromStr("America/Godthab")

  const Bool std := false
  const Bool dst := true
  Locale origLocale

//////////////////////////////////////////////////////////////////////////
// Test Setup
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    origLocale = Locale.current
    Locale.setCurrent(Locale.fromStr("en-US"))
  }

  override Void teardown()
  {
    Locale.setCurrent(origLocale)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    // equals
    verifyEq(DateTime.makeTicks(123_456_789), DateTime.makeTicks(123_456_789))
    verifyNotEq(DateTime.makeTicks(123_456_789), DateTime.makeTicks(123_456_780))

    // hash
    verifyEq(DateTime.makeTicks(123_456_789).hash, 123_456_789)
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(DateTime.makeTicks(723_456_789) >  DateTime.makeTicks(123_456_789))
    verify(DateTime.makeTicks(123_456_789) >= DateTime.makeTicks(123_456_789))
    verify(DateTime.makeTicks(123_456_789) <= DateTime.makeTicks(123_456_789))
    verify(DateTime.makeTicks(123_456_789) <  DateTime.makeTicks(723_456_789))
  }

//////////////////////////////////////////////////////////////////////////
// Now
//////////////////////////////////////////////////////////////////////////

  Void testNow()
  {
    verify(DateTime.now(null) !== DateTime.now(null))

    a := DateTime.now
    verify(a === DateTime.now)
    verifySame(a.timeZone, TimeZone.current)

    b := DateTime.now(null)
    verify(a !== b)
    verify(b === DateTime.now)

    Thread.sleep(200ms)
    verify(b === DateTime.now)

    c := DateTime.now(180ms)
    verify(b !== c)
  }

//////////////////////////////////////////////////////////////////////////
// Now
//////////////////////////////////////////////////////////////////////////

  Void testNowUtc()
  {
    verify(DateTime.nowUtc(null) !== DateTime.nowUtc(null))

    a := DateTime.nowUtc
    verify(a === DateTime.nowUtc)
    verifySame(a.timeZone, TimeZone.utc)

    b := DateTime.nowUtc(null)
    verify(a !== b)
    verify(b === DateTime.nowUtc)

    Thread.sleep(200ms)
    verify(b === DateTime.nowUtc)

    c := DateTime.now(180ms)
    verify(b !== c)
  }

//////////////////////////////////////////////////////////////////////////
// Boot
//////////////////////////////////////////////////////////////////////////

  Void testBoot()
  {
    verifySame(DateTime.boot, DateTime.boot)
    verifySame(DateTime.boot.timeZone, TimeZone.current)
    verify(DateTime.boot < DateTime.now(null))
  }

//////////////////////////////////////////////////////////////////////////
// Month
//////////////////////////////////////////////////////////////////////////

  Void testMonth()
  {
    verifyEq(Month#.qname, "sys::Month")
    verifySame(Month#.base, Enum#)
    verifySame(Month.jan.type, Month#)

    verifyEq(Month.values.isRO, true)
    verifyEq(Month.values.size, 12)
    verifyEq(Month.values.capacity, 12)
    verifyEnum(Month.jan, 0,  "jan", Month.values)
    verifyEnum(Month.feb, 1,  "feb", Month.values)
    verifyEnum(Month.mar, 2,  "mar", Month.values)
    verifyEnum(Month.apr, 3,  "apr", Month.values)
    verifyEnum(Month.may, 4,  "may", Month.values)
    verifyEnum(Month.jun, 5,  "jun", Month.values)
    verifyEnum(Month.jul, 6,  "jul", Month.values)
    verifyEnum(Month.aug, 7,  "aug", Month.values)
    verifyEnum(Month.sep, 8,  "sep", Month.values)
    verifyEnum(Month.oct, 9,  "oct", Month.values)
    verifyEnum(Month.nov, 10, "nov", Month.values)
    verifyEnum(Month.dec, 11, "dec", Month.values)

    verifySame(Month.jan.decrement, Month.dec)
    verifySame(Month.feb.decrement, Month.jan)
    verifySame(Month.dec.decrement, Month.nov)

    verifySame(Month.jan.increment, Month.feb)
    verifySame(Month.nov.increment, Month.dec)
    verifySame(Month.dec.increment, Month.jan)

    m := Month.jan
    verifySame(m--, jan); verifySame(m, dec)
    verifySame(--m, nov); verifySame(m, nov)
    verifySame(++m, dec); verifySame(m, dec)
    verifySame(m++, dec); verifySame(m, jan)
  }

  Void testMonthNumDays()
  {
    verifyEq(Month.jan.numDays(2007), 31)
    verifyEq(Month.feb.numDays(2007), 28)
    verifyEq(Month.feb.numDays(2004), 29)
    verifyEq(Month.mar.numDays(2007), 31)
    verifyEq(Month.apr.numDays(2007), 30)
    verifyEq(Month.may.numDays(2007), 31)
    verifyEq(Month.jun.numDays(2007), 30)
    verifyEq(Month.jul.numDays(2007), 31)
    verifyEq(Month.aug.numDays(2007), 31)
    verifyEq(Month.sep.numDays(2007), 30)
    verifyEq(Month.oct.numDays(2007), 31)
    verifyEq(Month.nov.numDays(2007), 30)
    verifyEq(Month.dec.numDays(2007), 31)
  }

  Void testMonthLocale()
  {
    verifyMonthLocale(Month.jan,  "1", "01", "Jan", "January")
    verifyMonthLocale(Month.feb,  "2", "02", "Feb", "February")
    verifyMonthLocale(Month.mar,  "3", "03", "Mar", "March")
    verifyMonthLocale(Month.apr,  "4", "04", "Apr", "April")
    verifyMonthLocale(Month.may,  "5", "05", "May", "May")
    verifyMonthLocale(Month.jun,  "6", "06", "Jun", "June")
    verifyMonthLocale(Month.jul,  "7", "07", "Jul", "July")
    verifyMonthLocale(Month.aug,  "8", "08", "Aug", "August")
    verifyMonthLocale(Month.sep,  "9", "09", "Sep", "September")
    verifyMonthLocale(Month.oct, "10", "10", "Oct", "October")
    verifyMonthLocale(Month.nov, "11", "11", "Nov", "November")
    verifyMonthLocale(Month.dec, "12", "12", "Dec", "December")

    verifyErr(ArgErr#) |,| { Month.jan.toLocale("") }
    verifyErr(ArgErr#) |,| { Month.jan.toLocale("MMMMM") }
    verifyErr(ArgErr#) |,| { Month.jan.toLocale("MMx") }
  }

  Void verifyMonthLocale(Month mon, Str m, Str mm, Str mmm, Str mmmm)
  {
    verifyEq(mon.toLocale("M"), m)
    verifyEq(mon.toLocale("MM"), mm)
    verifyEq(mon.toLocale("MMM"), mmm)
    verifyEq(mon.toLocale("MMMM"), mmmm)
    verifyEq(mon.toLocale(null), mmm)
    verifyEq(mon.localeAbbr, mmm)
    verifyEq(mon.localeFull, mmmm)
  }

//////////////////////////////////////////////////////////////////////////
// Weekday
//////////////////////////////////////////////////////////////////////////

  Void testWeekday()
  {
    verifyEq(Weekday#.qname, "sys::Weekday")
    verifySame(Weekday#.base, Enum#)
    verifySame(Weekday.sun.type, Weekday#)

    verifyEq(Weekday.values.isRO, true)
    verifyEq(Weekday.values.size, 7)
    verifyEq(Weekday.values.capacity, 7)
    verifyEnum(Weekday.sun, 0, "sun", Weekday.values)
    verifyEnum(Weekday.mon, 1, "mon", Weekday.values)
    verifyEnum(Weekday.tue, 2, "tue", Weekday.values)
    verifyEnum(Weekday.wed, 3, "wed", Weekday.values)
    verifyEnum(Weekday.thu, 4, "thu", Weekday.values)
    verifyEnum(Weekday.fri, 5, "fri", Weekday.values)
    verifyEnum(Weekday.sat, 6, "sat", Weekday.values)

    verifySame(Weekday.sun.decrement, Weekday.sat)
    verifySame(Weekday.thu.decrement, Weekday.wed)
    verifySame(Weekday.sat.decrement, Weekday.fri)

    verifySame(Weekday.sun.increment, Weekday.mon)
    verifySame(Weekday.fri.increment, Weekday.sat)
    verifySame(Weekday.sat.increment, Weekday.sun)

    w := Weekday.fri
    verifySame(w++, fri); verifySame(w, sat)
    verifySame(++w, sun); verifySame(w, sun)
    verifySame(--w, sat); verifySame(w, sat)
    verifySame(w--, sat); verifySame(w, fri)
  }

  Void verifyEnum(Enum e, Int ordinal, Str name, Enum[] values)
  {
    verifyEq(e.ordinal, ordinal)
    verifyEq(e.name, name)
    verifySame(values[ordinal], e)
  }

  Void testWeekdayLocale()
  {
    verifyEq(Weekday.localeStartOfWeek, Weekday.sun)
    verifyWeekdayLocale(Weekday.sun, "Sun", "Sunday")
    verifyWeekdayLocale(Weekday.mon, "Mon", "Monday")
    verifyWeekdayLocale(Weekday.tue, "Tue", "Tuesday")
    verifyWeekdayLocale(Weekday.wed, "Wed", "Wednesday")
    verifyWeekdayLocale(Weekday.thu, "Thu", "Thursday")
    verifyWeekdayLocale(Weekday.fri, "Fri", "Friday")
    verifyWeekdayLocale(Weekday.sat, "Sat", "Saturday")

    verifyErr(ArgErr#) |,| { Weekday.sun.toLocale("") }
    verifyErr(ArgErr#) |,| { Weekday.sun.toLocale("W") }
    verifyErr(ArgErr#) |,| { Weekday.sun.toLocale("WWWWW") }
    verifyErr(ArgErr#) |,| { Weekday.sun.toLocale("x") }
  }

  Void verifyWeekdayLocale(Weekday w, Str www, Str wwww)
  {
    verifyEq(w.toLocale("WWW"), www)
    verifyEq(w.toLocale("WWWW"), wwww)
    verifyEq(w.toLocale(null), www)
    verifyEq(w.localeAbbr, www)
    verifyEq(w.localeFull, wwww)
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  Void testMath()
  {
    now := DateTime.now

    yesterday := now + -1day
    tomorrow := now + 1day

    verifyEq(now.ticks - yesterday.ticks, 1day.ticks)
    verifyEq(now.ticks - tomorrow.ticks, -1day.ticks)

    verifyEq(now - yesterday, 1day)
    verifyEq(now - tomorrow, -1day)
  }

  Void testFloor()
  {
    now := DateTime.now
    verifyEq(now.floor(1min).ticks % 1min.ticks, 0)
    verifyEq(now.floor(1sec).ticks % 1sec.ticks, 0)
    now += 1234567890ns
    verifyEq(now.floor(1min).ticks % 1min.ticks, 0)
    verifyEq(now.floor(1sec).ticks % 1sec.ticks, 0)

    x := DateTime.make(2008, Month.mar, 14, 12, 30, 44)
    verifyEq(x.floor(1hr), DateTime.make(2008, Month.mar, 14, 12, 00))
    verifyEq(x.floor(1min), DateTime.make(2008, Month.mar, 14, 12, 30))
    verifySame(x.floor(1sec), x)
  }

//////////////////////////////////////////////////////////////////////////
// TimeZone
//////////////////////////////////////////////////////////////////////////

  Void testTimeZone()
  {
    names := TimeZone.listNames
    verify(names.isRO)
    verify(names.contains("New_York"))
    verify(names.contains("Los_Angeles"))
    verify(names.contains("London"))
    verify(names.contains("UTC"))
    verify(!names.contains("America/New_York"))

    names = TimeZone.listFullNames
    verify(names.isRO)
    verify(names.contains("America/New_York"))
    verify(names.contains("America/Los_Angeles"))
    verify(names.contains("Europe/London"))
    verify(names.contains("Etc/UTC"))
    verify(!names.contains("New_York"))

    verify(TimeZone.fromStr("foo bar", false) == null)
    verifyErr(ParseErr#) |,| { TimeZone.fromStr("foo bar") }

    x := TimeZone.fromStr("America/New_York")
    verifyEq(x.name,  "New_York")
    verifyEq(x.toStr, "New_York")
    verifyEq(x.fullName, "America/New_York")
    verifyEq(x.stdAbbr(2007), "EST")
    verifyEq(x.dstAbbr(2007), "EDT")
    verifyEq(x.offset(2007), -5hr)
    verifyEq(x.dstOffset(2007), 1hr)
    verifySame(TimeZone.fromStr("New_York"), x)

    x = TimeZone.fromStr("Phoenix")
    verifyEq(x.name,  "Phoenix")
    verifyEq(x.toStr, "Phoenix")
    verifyEq(x.fullName, "America/Phoenix")
    verifyEq(x.stdAbbr(2007), "MST")
    verifyEq(x.dstAbbr(2007), null)
    verifyEq(x.offset(2007), -7hr)
    verifyEq(x.dstOffset(2007), null)
    verifySame(TimeZone.fromStr("America/Phoenix"), x)

    x = TimeZone.fromStr("Asia/Calcutta")
    verifyEq(x.stdAbbr(2007), "IST")
    verifyEq(x.dstAbbr(2007), null)
    verifyEq(x.offset(2007), 5.5hr)
    verifyEq(x.dstOffset(2007), null)
  }

  Void testToTimeZone()
  {
    a := DateTime.fromStr("2008-11-14T12:00:00Z UTC")
    b := a.toTimeZone(ny)
    verifyEq(b.toStr, "2008-11-14T07:00:00-05:00 New_York")
    verifySame(a, a.toTimeZone(utc))
    verifySame(a, a.toUtc)
    verifySame(b, b.toTimeZone(ny))
    verifyEq(a, b.toUtc)

    c := b.toTimeZone(la)
    verifyEq(c, DateTime.make(2008, Month.nov, 14, 4, 0, 0, 0, la))
    d := c.toTimeZone(ny)
    verifyEq(d, b)

    x := DateTime.fromStr("2008-04-06T05:21:20-08:00 Los_Angeles")
    y := DateTime.fromStr("2008-04-06T09:21:20-04:00 New_York")
    verifyEq(x.ticks, y.ticks)
  }

//////////////////////////////////////////////////////////////////////////
// Leap Year
//////////////////////////////////////////////////////////////////////////

  Void testLeapYear()
  {
    verifyEq(DateTime.isLeapYear(2000), true)
    verifyEq(DateTime.isLeapYear(2007), false)
    verifyEq(DateTime.isLeapYear(2008), true)
    verifyEq(DateTime.isLeapYear(2012), true)
    verifyEq(DateTime.isLeapYear(2100), false)
    verifyEq(DateTime.isLeapYear(2400), true)
  }

//////////////////////////////////////////////////////////////////////////
// Weekday In Month
//////////////////////////////////////////////////////////////////////////

  Void testWeekdayInMonth()
  {
    verifyWeekdayInMonth(2007, feb, thu, [1, 8, 15, 22])
    verifyWeekdayInMonth(2007, feb, fri, [2, 9, 16, 23])
    verifyWeekdayInMonth(2007, feb, sat, [3, 10, 17, 24])
    verifyWeekdayInMonth(2007, feb, sun, [4, 11, 18, 25])
    verifyWeekdayInMonth(2007, feb, mon, [5, 12, 19, 26])
    verifyWeekdayInMonth(2007, feb, tue, [6, 13, 20, 27])
    verifyWeekdayInMonth(2007, feb, wed, [7, 14, 21, 28])

    verifyWeekdayInMonth(2008, mar, sat, [1, 8, 15, 22, 29])
    verifyWeekdayInMonth(2008, mar, sun, [2, 9, 16, 23, 30])
    verifyWeekdayInMonth(2008, mar, mon, [3, 10, 17, 24, 31])
    verifyWeekdayInMonth(2008, mar, tue, [4, 11, 18, 25])
    verifyWeekdayInMonth(2008, mar, wed, [5, 12, 19, 26])
    verifyWeekdayInMonth(2008, mar, thu, [6, 13, 20, 27])
    verifyWeekdayInMonth(2008, mar, fri, [7, 14, 21, 28])

    verifyWeekdayInMonth(2007, oct, wed, [3, 10, 17, 24, 31])
    verifyWeekdayInMonth(1997, nov, sat, [1, 8, 15, 22, 29])
    verifyWeekdayInMonth(1980, jan, mon, [7, 14, 21, 28])
    verifyWeekdayInMonth(2016, feb, mon, [1, 8, 15, 22, 29])

    verifyEq(DateTime.weekdayInMonth(2007, Month.oct, Weekday.sun, -1), 28)
    verifyErr(ArgErr#) |,| { DateTime.weekdayInMonth(2007, oct, mon, 0) }
    verifyErr(ArgErr#) |,| { DateTime.weekdayInMonth(2007, oct, wed, 6) }
    verifyErr(ArgErr#) |,| { DateTime.weekdayInMonth(2016, feb, tue, -5) }
  }

  Void verifyWeekdayInMonth(Int year, Month mon, Weekday weekday, Int[] days)
  {
    days.each |Int day, Int i|
    {
      verifyEq(DateTime.weekdayInMonth(year, mon, weekday, i+1), day)
      verifyEq(DateTime.weekdayInMonth(year, mon, weekday, i-days.size), day)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Makes
//////////////////////////////////////////////////////////////////////////

  Void testMakes()
  {
    // smoke tests
    verifyDateTime(2678400000_000000, utc,  2000, feb, 1,  0, 0, 0, tue, std, 32)
    verifyDateTime(5270400000_000001, utc,  2000, mar, 2,  0, 0, 0, thu, std, 62, 1)
    verifyDateTime(8035200123_000000, utc,  2000, apr, 3,  0, 0, 0, mon, std, 94, 123_000_000)
    verifyDateTime(10713600000_789000, utc, 2000, may, 4,  0, 0, 0, thu, std, 125, 789000)
    verifyDateTime(13478400000_000000, utc, 2000, jun, 5,  0, 0, 0, mon, std)
    verifyDateTime(16156800000_000000, utc, 2000, jul, 6,  0, 0, 0, thu, std)
    verifyDateTime(18921600000_000000, utc, 2000, aug, 7,  0, 0, 0, mon, std)
    verifyDateTime(21686400123_456789, utc, 2000, sep, 8,  0, 0, 0, fri, std, null, 123_456_789)
    verifyDateTime(24364800000_000000, utc, 2000, oct, 9,  0, 0, 0, mon, std)
    verifyDateTime(27129600000_000000, utc, 2000, nov, 10, 0, 0, 0, fri, std)
    verifyDateTime(29808000000_000000, utc, 2000, dec, 11, 0, 0, 0, mon, std, 346)
    verifyDateTime(-615427197000_000000, utc, 1980, jul, 1, 0, 0, 3, tue, std)
    verifyDateTime(-869961540100_000000, utc, 1972, jun, 7, 0, 0, 59, wed, std, null, 900_000_000)
    verifyDateTime(-869961576544_000000, utc, 1972, jun, 7, 0, 0, 23, wed, std, null, 456_000_000)

    // Fan epoch is 1-jan-2000
    verifyDateTime(0, utc, 2000, jan, 1, 0, 0, 0, sat, std)

    // Java epoch is 1-jan-1970
    verifyDateTime((-10957day).ticks, utc, 1970, jan, 1, 0, 0, 0, thu, std)

    // Boundary condition for leap table monForDayOfYearLeap
    verifyDateTime(-220906800000_000000, ny, 1992, dec, 31, 0, 0, 0, thu, std)

    // Fan epoch +1day
    verifyDateTime(86400000_000000, utc, 2000, jan, 2, 0, 0, 0, sun, std)

    // right now as I code this
    verifyDateTime(245209531000_000099, ny, 2007, oct, 8, 21, 45, 31, mon, dst, null, 99)

    // Halloween 2008 (dst)
    verifyDateTime(278744523000_000000, ny, 2008, oct, 31, 1, 2, 3, fri, dst)

    // Halloween 2006 (std)
    verifyDateTime(215589723000_000000, ny, 2006, oct, 31, 1, 2, 3, tue, std)

    // 2008 Feb 29 leap year
    verifyDateTime(257621400000_000000, ny, 2008, feb, 29, 12, 30, 0, fri, std)

    // 1972 Jun 7
    verifyDateTime(-869917500000_000000, ny, 1972, jun, 7, 8, 15, 0, wed, dst)

    // 2001 Jan 30
    verifyDateTime(34153380000_000000, ny, 2001, jan, 30, 2, 3, 0, tue, std)

    // 2099 Dec 31 (upper boundary)
    verifyDateTime(3155759999000_000000, utc, 2099, dec, 31, 23, 59, 59, thu, std)

    // 1901 Jan 1 (lower boundary UTC)
    verifyDateTime(-3124137600000_000000, utc, 1901, jan, 1, 0, 0, 0, tue, std)

    // clearly EDT
    verifyDateTime(269598645000_000000, ny, 2008, jul, 17, 4, 30, 45, thu, dst)

    // PST->PDT mar edge
    verifyDateTime(447670800000_000000, la, 2014, mar, 9, 1, 0, 0, sun, std)
    verifyDateTime(447674399000_000000, la, 2014, mar, 9, 1, 59, 59, sun, std)
    verifyDateTime(447674400000_000000, la, 2014, mar, 9, 3, 0, 0, sun, dst)

    // PDT->PST nov edge
    verifyDateTime(310377599000_000000, la, 2009, nov, 1, 0, 59, 59, sun, dst)
    verifyDateTime(310381199000_000000, la, 2009, nov, 1, 1, 59, 59, sun, dst)
    verifyDateTime(310381200000_000000, la, 2009, nov, 1, 1, 0, 0, sun, std, null, 0, false)
    verifyDateTime(310384800000_000000, la, 2009, nov, 1, 2, 0, 0, sun, std)
    verifyDateTime(310384807000_000000, la, 2009, nov, 1, 2, 0, 7, sun, std)

    // Amsterdam (+1, with universal dst mode)
    verifyDateTime(289220400000_000000, nl, 2009, mar, 1,  12, 0, 0, sun, std)
    verifyDateTime(291601800000_000000, nl, 2009, mar, 29, 1, 30, 0, sun, std)
    verifyDateTime(291603600000_000000, nl, 2009, mar, 29, 3, 0, 0,  sun, dst)
    verifyDateTime(291722400000_000000, nl, 2009, mar, 30, 12, 0, 0, mon, dst)

    // Kiev (+2, with universal dst mode)
    verifyDateTime(289216800000_000000, kiev, 2009, mar, 1, 12, 0, 0, sun, std)
    verifyDateTime(291592800000_000000, kiev, 2009, mar, 29, 0, 0, 0, sun, std)
    verifyDateTime(291596400000_000000, kiev, 2009, mar, 29, 1, 0, 0, sun, std)
    verifyDateTime(291600000000_000000, kiev, 2009, mar, 29, 2, 0, 0, sun, std)
    verifyDateTime(291603600000_000000, kiev, 2009, mar, 29, 4, 0, 0, sun, dst)
    verifyDateTime(291718800000_000000, kiev, 2009, mar, 30, 12, 0, 0, mon, dst)
    verifyDateTime(309733200000_000000, kiev, 2009, oct, 25, 0, 0, 0, sun, dst)
    verifyDateTime(309736800000_000000, kiev, 2009, oct, 25, 1, 0, 0, sun, dst)
    verifyDateTime(309740400000_000000, kiev, 2009, oct, 25, 2, 0, 0, sun, dst)
    verifyDateTime(309747600000_000000, kiev, 2009, oct, 25, 3, 0, 0, sun, std)
    verifyDateTime(309751200000_000000, kiev, 2009, oct, 25, 4, 0, 0, sun, std)

    // Brazil (southern hemisphere with wall dst, and midnight dst)
    verifyDateTime(252511200000_000000, brazil, 2008, jan, 1, 12, 0, 0, tue, dst)
    verifyDateTime(257090400000_000000, brazil, 2008, feb, 23, 12, 0, 0, sat, dst)
    verifyDateTime(257133599000_000000, brazil, 2008, feb, 23, 23, 59, 59, sat, dst)
    verifyDateTime(257137199000_000000, brazil, 2008, feb, 23, 23, 59, 59, sat, std, null, 0, false)
    verifyDateTime(257180400000_000000, brazil, 2008, feb, 24, 12, 0, 0, sun, std)
    verifyDateTime(257266800000_000000, brazil, 2008, feb, 25, 12, 0, 0, mon, std)
    verifyDateTime(257698800000_000000, brazil, 2008, mar, 1, 12, 0, 0, sat, std)
    verifyDateTime(278906400000_000000, brazil, 2008, nov, 1, 23, 0, 0, sat, std)
    verifyDateTime(278910000000_000000, brazil, 2008, nov, 2, 1,  0, 0, sun, dst)
    verifyDateTime(278949600000_000000, brazil, 2008, nov, 2, 12, 0, 0, sun, dst)

    // New South Wales (south hemisphere, standard (non-wall) time dst)
    verifyDateTime(246815999000_000000, aust, 2007, oct, 28, 1, 59, 59, sun, std)
    verifyDateTime(246816000000_000000, aust, 2007, oct, 28, 3, 0, 0, sun, dst)
    verifyDateTime(252435906000_000000, aust, 2008, jan, 1, 4, 5, 6, tue, dst)
    verifyDateTime(260326800000_000000, aust, 2008, apr, 1, 12, 0, 0, tue, dst)
    verifyDateTime(260726399999_000000, aust, 2008, apr, 6, 2, 59, 59, sun, dst, null, 999_000_000, false)
    verifyDateTime(260726400000_000000, aust, 2008, apr, 6, 2, 0, 0, sun, std)
    verifyDateTime(260730000000_000000, aust, 2008, apr, 6, 3, 0, 0, sun, std)
    verifyDateTime(261972000000_000000, aust, 2008, apr, 20, 12, 0, 0, sun, std)
    verifyDateTime(276430500000_000000, aust, 2008, oct, 4, 20, 15, 0, sat, std)
    verifyDateTime(276451199000_000000, aust, 2008, oct, 5, 1, 59, 59, sun, std)
    verifyDateTime(276451200000_000000, aust, 2008, oct, 5, 3, 0, 0, sun, dst)

    // Riga did not observe dst in 2000
    verifyDateTime(78786000000_000000,  riga, 2002, jul, 1, 0, 0, 0, mon, dst)
    verifyDateTime(47250000000_000000,  riga, 2001, jul, 1, 0, 0, 0, sun, dst)
    verifyDateTime(15717600000_000000,  riga, 2000, jul, 1, 0, 0, 0, sat, std)
    verifyDateTime(-15908400000_000000, riga, 1999, jul, 1, 0, 0, 0, thu, dst)

    // Israel
    verifyDateTime(195170400000_000000, jeru, 2006, mar,  9, 0, 0, 0, thu, std)
    verifyDateTime(195256800000_000000, jeru, 2006, mar, 10, 0, 0, 0, fri, std)
    verifyDateTime(195343200000_000000, jeru, 2006, mar, 11, 0, 0, 0, sat, std)
    verifyDateTime(197071200000_000000, jeru, 2006, mar, 31, 0, 0, 0, fri, std)
    verifyDateTime(197154000000_000000, jeru, 2006, apr,  1, 0, 0, 0, sat, dst)

    // St. John has -3:30 offset
    verifyDateTime(255148200000_000000, stJohn, 2008, jan, 31, 23, 0, 0, thu, std)
    verifyDateTime(255151800000_000000, stJohn, 2008, feb, 1, 0, 0, 0, fri, std)

    // Godthab Greenland uses universal time like EU but with negative GMT offset
    verifyDateTime(246985200000_000000, godthab, 2007, oct, 29, 12, 0, 0, mon, std)
    verifyDateTime(260074800000_000000, godthab, 2008, mar, 29, 0, 0, 0, sat, std)
    verifyDateTime(260154000000_000000, godthab, 2008, mar, 29, 23, 0, 0, sat, dst)

   // Original notes I captured for testing:
   //  - Chile, etc which starts DST in the fall
   //  - Perth which canceled dst in 2007 and has the year roll over
   //  - Test changes to zone items
   //  - Test changes to zone times with an until not cleanly on year boundary (Asia/Bishkek)
   //  - Future rules for Asia/Jerusalem

    // out of bounds
    verifyErr(ArgErr#) |,| { DateTime.make(1899, Month.jun, 1, 0, 0) }
    verifyErr(ArgErr#) |,| { DateTime.make(2100, Month.jun, 1, 0, 0) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.feb, 0, 0, 0) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.feb, 29, 0, 0) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, -1, 0) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 60, 00) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, -1) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, 60) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, 0, -1) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, 0, 60) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, 0, 0, -1) }
    verifyErr(ArgErr#) |,| { DateTime.make(2007, Month.jun, 6, 0, 0, 0, 1_000_000_000) }
    verifyErr(ArgErr#) |,| { DateTime.makeTicks(-3124137600000_000001, utc) }
    verifyErr(ArgErr#) |,| { DateTime.makeTicks(3155760000000_000000, utc) }
  }

  Void verifyDateTime(Int ticks, TimeZone tz, Int year, Month month, Int day,
                      Int hr, Int min, Int sec,
                      Weekday weekday, Bool isDST, Int? doy := null,
                      Int nanoSec := 0, Bool testMake := true)
  {
    func := |DateTime dt|
    {
      verifySame(dt.timeZone, tz)
      verifyEq(dt.ticks,   ticks)
      verifyEq(dt.year,    year)
      verifyEq(dt.month,   month)
      verifyEq(dt.day,     day)
      verifyEq(dt.hour,    hr)
      verifyEq(dt.min,     min)
      verifyEq(dt.sec,     sec)
      verifyEq(dt.nanoSec, nanoSec)
      verifyEq(dt.weekday, weekday)
      verifyEq(dt.dst,     isDST)
      verifyEq(dt.timeZoneAbbr, isDST ? tz.dstAbbr(year) : tz.stdAbbr(year))
      if (doy != null) verifyEq(dt.dayOfYear, doy)
    }

    dtA := DateTime.makeTicks(ticks, tz)
    dtB := DateTime.make(year, month, day, hr, min, sec, nanoSec, tz)
    func(dtA)
    if (testMake) func(dtB)

    // verify toStr -> fromStr round trip
    dtR := DateTime.fromStr(dtA.toStr)
    verifyEq(dtA, dtR)
    verifyEq(dtA.toStr, dtR.toStr)
    func(dtR)
  }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  Void testToStr()
  {
    d := DateTime.makeTicks(8035200123_000000, utc)
    verifyEq(d.toStr, "2000-04-03T00:00:00.123Z UTC")

    d = DateTime.makeTicks(278744523000_000089, ny)
    verifyEq(d.toStr, "2008-10-31T01:02:03.000000089-04:00 New_York")

    d = DateTime.makeTicks(215589723000_000000, ny)
    verifyEq(d.toStr, "2006-10-31T01:02:03-05:00 New_York")

    d = DateTime.makeTicks(289220400000_000000, nl)
    verifyEq(d.toStr, "2009-03-01T12:00:00+01:00 Amsterdam")

    d = DateTime.makeTicks(290000000000_000000, uk)
    verifyEq(d.toStr, "2009-03-10T11:33:20Z London")

    verifyFromStrErr("2009^03-01T12:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03^01T12:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01^12:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12^00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00^00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:00^01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:00+01^00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:00+01:00^Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:00+01:00 FooBar")
    verifyFromStrErr("3000-03-01T12:00:00+01:00 FooBar")
    verifyFromStrErr("2009-13-01T12:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-32T12:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T24:00:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:61:00+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:99+01:00 Amsterdam")
    verifyFromStrErr("2009-03-01T12:00:00+01 Amsterdam")
  }

  Void verifyFromStrErr(Str s)
  {
    verifyEq(DateTime.fromStr(s, false), null)
    verifyErr(ParseErr#) |,| { DateTime.fromStr(s) }
    verifyErr(ParseErr#) |,| { DateTime.fromStr(s, true) }
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  Void testLocale()
  {
    // basic fields
    x := DateTime.make(2008, Month.feb, 5, 3, 7, 20, 123_000_000, ny)
    verifyEq(x.toLocale("YY, YYYY"), "08, 2008")
    verifyEq(x.toLocale("M, MM, MMM, MMMM"), "2, 02, Feb, February")
    verifyEq(x.toLocale("D, DD"), "5, 05")
    verifyEq(x.toLocale("WWW WWWW"), "Tue Tuesday")
    verifyEq(x.toLocale("h, hh, k, kk, a"), "3, 03, 3, 03, AM")
    verifyEq(x.toLocale("m, mm"), "7, 07")
    verifyEq(x.toLocale("s, ss"), "20, 20")
    verifyEq(x.toLocale("f, ff, fff, ffff, fffff"), "1, 12, 123, 1230, 12300")
    verifyEq(x.toLocale("F, FF, FFF, FFFF, FFFFF"), "1, 12, 123, 123, 123")
    verifyEq(x.toLocale("F, fF, ffF, ffFF, ffffF"), "1, 12, 123, 123, 1230")
    verifyEq(x.toLocale("z, zzz, zzzz"), "-05:00, EST, New_York")

    // US locale default pattern
    verifyEq(x.toLocale(),     "5-Feb-2008 Tue 03:07:20 EST")
    verifyEq(x.toLocale(null), "5-Feb-2008 Tue 03:07:20 EST")

    // 12-hour AM/PM
    x = DateTime.make(2007, Month.may, 9, 0, 5, 0, 0, ny)
    verifyEq(x.toLocale("kk:mma"), "12:05AM")
    x = DateTime.make(2007, Month.may, 9, 12, 0, 0, 0, ny)
    verifyEq(x.toLocale("kk:mma"), "12:00PM")
    x = DateTime.make(2007, Month.may, 9, 23, 12, 00, 0, ny)
    verifyEq(x.toLocale("kk:mma"), "11:12PM")

    // time zones
    x = DateTime.make(2007, Month.jun, 17, 1, 2, 3, 0, utc)
    verifyEq(x.toLocale("YYMMDDkkmmssz"), "070617010203Z")
    x = DateTime.make(2007, Month.jun, 17, 1, 2, 3, 0, ny)
    verifyEq(x.toLocale("z|zzz|zzzz"), "-04:00|EDT|New_York")
    x = DateTime.makeTicks(255148200000_000000, stJohn)
    verifyEq(x.toLocale("z|zzz|zzzz"), "-03:30|NST|St_Johns")
    x = DateTime.makeTicks(291718800000_000000, kiev)
    verifyEq(x.toLocale("z|zzz|zzzz"), "+03:00|EEST|Kiev")

    // fractions
    x = DateTime.make(2007, Month.jun, 17, 1, 2, 3, 123_456_789, utc)
    verifyEq(x.toLocale("f, ff, fff, ffff, fffff"), "1, 12, 123, 1234, 12345")
    verifyEq(x.toLocale("F, FF, FFF, FFFF, FFFFF"), "1, 12, 123, 1234, 12345")
    verifyEq(x.toLocale("ffffff, fffffff, ffffffff, fffffffff"), "123456, 1234567, 12345678, 123456789")
    verifyEq(x.toLocale("FFFFFF, FFFFFFF, FFFFFFFF, FFFFFFFFF"), "123456, 1234567, 12345678, 123456789")
    verifyEq(x.toLocale("fffFFF, fFFFFFF, fffffffF, fffffffFF"), "123456, 1234567, 12345678, 123456789")
    x = DateTime.make(2007, Month.jun, 17, 1, 2, 3, 009_870_000, utc)
    verifyEq(x.toLocale("f,ff,fff,ffff,fffff,ffffff"), "0,00,009,0098,00987,009870")
    verifyEq(x.toLocale("F,FF,FFF,FFFF,FFFFF,FFFFFF"), "0,00,009,0098,00987,00987")
    verifyEq(x.toLocale("fffFF,fffFFF,ffffffFFF"), "00987,00987,009870")
    x = DateTime.make(2007, Month.jun, 17, 1, 2, 3, 0, utc)
    verifyEq(x.toLocale("|f, |F, |fF"), "|0, , |0")

    // literals
    x = DateTime.make(2007, Month.may, 9, 15, 30, 0, 0, ny)
    verifyEq(x.toLocale("YYMMDD'T'hhmm"), "070509T1530")
    verifyEq(x.toLocale("'It is' k:mma!"), "It is 3:30PM!")

    // errors
    verifyErr(ArgErr#) |,| { x.toLocale("Y") }
    verifyErr(ArgErr#) |,| { x.toLocale("YYY") }
    verifyErr(ArgErr#) |,| { x.toLocale("YYYYY") }
    verifyErr(ArgErr#) |,| { x.toLocale("MMMMM") }
    verifyErr(ArgErr#) |,| { x.toLocale("DDD") }
    verifyErr(ArgErr#) |,| { x.toLocale("WW") }
    verifyErr(ArgErr#) |,| { x.toLocale("WWWWW") }
    verifyErr(ArgErr#) |,| { x.toLocale("hhh") }
    verifyErr(ArgErr#) |,| { x.toLocale("kkk") }
    verifyErr(ArgErr#) |,| { x.toLocale("aa") }
    verifyErr(ArgErr#) |,| { x.toLocale("mmm") }
    verifyErr(ArgErr#) |,| { x.toLocale("sss") }
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  Void testJava()
  {
    x := DateTime.fromJava(1227185341155, ny)
    verifyEq(x.timeZone, ny)
    verifyEq(x.year, 2008)
    verifyEq(x.month, Month.nov)
    verifyEq(x.day, 20)
    verifyEq(x.hour, 7)
    verifyEq(x.min, 49)
    verifyEq(x.toJava, 1227185341155)
 }

//////////////////////////////////////////////////////////////////////////
// HTTP
//////////////////////////////////////////////////////////////////////////

  Void testHttpStr()
  {
    x := DateTime.make(1994, Month.nov, 6, 8, 49, 37, 0, utc)
    verifyEq(DateTime.fromHttpStr("Sun, 06 Nov 1994 08:49:37 GMT"), x)
    verifyEq(DateTime.fromHttpStr("Sunday, 06-Nov-94 08:49:37 GMT"), x)
    verifyEq(DateTime.fromHttpStr("Sun Nov  6 08:49:37 1994"), x)
    verifyEq(x.toHttpStr, "Sun, 06 Nov 1994 08:49:37 GMT")

    verifyEq(DateTime.fromHttpStr("06 Nov 1994 08:49:37", false), null)
    verifyErr(ParseErr#) |,| { DateTime.fromHttpStr("Sun, 06 Nov 08:49:37 GMT") }
  }

}