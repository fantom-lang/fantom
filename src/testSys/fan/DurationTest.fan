//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Apr 06  Brian Frank  Creation
//

**
** DurationTest
**
class DurationTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Is
//////////////////////////////////////////////////////////////////////////

  Void testIs()
  {
    verify(3ms.type === Duration#)

    verify(0sec is Obj)
    verify(3ms is Duration)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    verify(0ms == 0sec)
    verify(1ms != 1sec)
    verify(9hr != null)
    verify(null != 8ns)
    verify(8ns as Obj != 8)
  }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  Void testLiterals()
  {
    verifyEq(3ns.ticks,   3)
    verifyEq(3ms.ticks,   3_000_000)
    verifyEq(3sec.ticks,  3_000_000_000)
    verifyEq(-3sec.ticks, -3_000_000_000)
    verifyEq(1min.ticks,  60_000_000_000)
    verifyEq(1hr.ticks,   3_600_000_000_000)
    verifyEq(1day.ticks,  86_400_000_000_000)

    verifyEq(0.5hr.ticks,    1_800_000_000_000)
    verifyEq(-2.5hr.ticks,   -9_000_000_000_000)
    verifyEq(0.001sec.ticks, 1_000_000)
  }

//////////////////////////////////////////////////////////////////////////
// Boot/Uptime
//////////////////////////////////////////////////////////////////////////

  Void testBoot()
  {
    verifySame(Duration.boot, Duration.boot)
    verify(Duration.boot < Duration.now)
    verify(Duration.uptime > 0ns)
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(2ns < 3ns)
    verify(2ns < 2ms)
    verify(null < 3ns)
    verifyFalse(3ns < 3ns)
    verifyFalse(6ns < 4ns)
    verifyFalse(3ns < null)

    verify(3ns <= 3ns)
    verify(3ns <= 3ns)
    verify(null <= 3ns)
    verifyFalse(6ns <= 5ns)
    verifyFalse(5ns <= null)

    verify(-2ns > -3ns)
    verify(0ns > -2ns)
    verify(-2ns > null)
    verifyFalse(null > 77ns)
    verifyFalse(3ns > 4ns)

    verify(-3ms >= -4ms)
    verify(-3ms >= -3ms)
    verify(-3ms >= null)
    verifyFalse(null >= 4ms)
    verifyFalse(-3ms >= -2ms)

    verifyEq(3ms <=> 4ms, -1)
    verifyEq(3ms <=> 3ms, 0)
    verifyEq(4ms <=> 3ms, 1)
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  Void testMath()
  {
    x := 2hr
    verifyEq(-x, -2hr)
    verifyEq(x + 1min, 121min)
    verifyEq(x - 1day, -22hr)
    verifyEq(x * 3f, 6hr)
    verifyEq(x * 0.25f, 30min)
    verifyEq(x / 12f, 10min)
    verifyEq(x / 0.5f, 4hr)
  }

//////////////////////////////////////////////////////////////////////////
// ToInt
//////////////////////////////////////////////////////////////////////////

  Void testToInt()
  {
    verifyEq(123_456_789ns.toMillis, 123)
    verifyEq(34_567ms.toSec, 34)
    verifyEq(123sec.toMin, 2)
    verifyEq(123_456_789sec.toHour, 34293)
    verifyEq(123_456_789sec.toDay, 1428)
  }

//////////////////////////////////////////////////////////////////////////
// Floor
//////////////////////////////////////////////////////////////////////////

  Void testFloor()
  {
    verifySame(2sec.floor(1sec), 2sec)
    verifyEq(119999ms.floor(1min), 1min)
    verifyEq(120001ms.floor(1min), 2min)
    verifyEq(123500ms.floor(1sec), 123sec)
    verifySame(123500ms.floor(1ms), 123500ms)
  }

//////////////////////////////////////////////////////////////////////////
// Parse/Str
//////////////////////////////////////////////////////////////////////////

  Void testStr()
  {
    // whole numbers
    verifyStr(1ns, "1ns")
    verifyStr(7ns, "7ns")
    verifyStr(-99ms, "-99ms")
    verifyStr(61sec, "61sec")
    verifyStr(60sec, "1min")
    verifyStr(100min, "100min")
    verifyStr(-5hr, "-5hr")
    verifyStr(365day, "365day")
    verifyStr(54750day, "54750day") // 150yr

    // TODO - underbars?

    // fractions
    verifyEq(0.5hr.toStr, "30min")
    verifyEq(Duration.fromStr("0.5hr"), 0.5hr)
    verifyEq((-1.5day).toStr, "-36hr")
    verifyEq(Duration.fromStr("-1.5day"), -36hr)

    // invalid
    verifyErr(ParseErr#) |,| { Duration.fromStr("4") }
    verifyErr(ParseErr#) |,| { Duration.fromStr("4x") }
    verifyErr(ParseErr#) |,| { Duration.fromStr("4seconds") }
    verifyErr(ParseErr#) |,| { Duration.fromStr("xms") }
    verifyErr(ParseErr#) |,| { Duration.fromStr("x4ms") }
    verifyErr(ParseErr#) |,| { Duration.fromStr("4days") }
  }

  Void verifyStr(Duration dur, Str format)
  {
    verifyEq(dur.toStr, format)
    verifyEq(Duration.fromStr(format), dur)
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  Void testLocale()
  {
    verifyEq(0ns.toLocale, "0ns")
    verifyEq(1ns.toLocale, "1ns")
    verifyEq(3ns.toLocale, "3ns")
    verifyEq(999ns.toLocale, "999ns")
    verifyEq(3000ns.toLocale, "0.003ms")
    verifyEq(78000ns.toLocale, "0.078ms")
    verifyEq(800_000ns.toLocale, "0.8ms")
    verifyEq(803_900ns.toLocale, "0.803ms")
    verifyEq(1_123_000ns.toLocale, "1.123ms")
    verifyEq(1ms.toLocale, "1.0ms")
    verifyEq(2ms.toLocale, "2ms")
    verifyEq(1999ms.toLocale, "1999ms")
    verifyEq(2004ms.toLocale, "2sec")
    verifyEq((6sec+88ms).toLocale, "6sec")
    verifyEq((5min+2sec).toLocale, "5min 2sec")
    verifyEq((10hr + 5min+2sec).toLocale, "10hr 5min 2sec")
    verifyEq((1day + 10hr + 5min+2sec).toLocale, "1day 10hr 5min 2sec")
    verifyEq((3day + 55sec).toLocale, "3days 0hr 0min 55sec")
  }

}
