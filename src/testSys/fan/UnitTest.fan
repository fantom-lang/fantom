//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 08  Brian Frank  Creation
//

**
** UnitTest
**
@Js
class UnitTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void testParse()
  {
    verifyParse("test_1;t1;kg2*m-3;33;100",
      "test_1", "t1", ["kg":2, "m":-3], 33f, 100f)

    verifyParse("test_2 ; t2 ;  kg1 * m 2 * sec3*K4*A5*mol6*cd7 ; -99 ;  -77",
      "test_2", "t2", ["kg":1, "m":2, "sec":3, "K":4, "A":5, "mol":6, "cd":7], -99f, -77f)

    verifyParse("test_3; t3; sec1; 1E10",
      "test_3", "t3", ["sec":1], 1E10f, 0f)

    verifyParse("test_4; t4; m-9",
      "test_4", "t4", ["m":-9], 1f, 0f)

    verifyParse("test_5; t5",
      "test_5", "t5", Str:Int[:], 1f, 0f)

    verifyParse("test_6",
      "test_6", "test_6", Str:Int[:], 1f, 0f)

    verifyParse("test_7;;kg2",
      "test_7", "test_7", ["kg":2], 1f, 0f)

    verifyErr(ParseErr#) { Unit("test_8;t8;foo2") }
    verifyErr(ParseErr#) { Unit("test_8;t8;m2;xx") }
    verifyErr(ParseErr#) { Unit("test_8;t8;m2;5;#") }

    verifyEq(Unit.find("test_8", false), null)
    verifyErr(Err#) { Unit.find("test_8") }
    verifyErr(Err#) { Unit.find("test_8", true) }
  }

  Void verifyParse(Str s, Str n, Str sym, Str:Int dim, Float scale, Float offset := 0f)
  {
    // parse
    u := Unit(s)

    // verify identity
    verifyEq(u.name, n)
    verifyEq(u.symbol, sym)
    verifyEq(u.scale, scale)
    verifyEq(u.offset, offset)
    verifyEq(u, u)
    verifyEq(u.hash, u.toStr.hash)
    zeroes := ["kg", "m", "sec", "K", "A", "mol", "cd"].exclude |Str k->Bool| { return dim.keys.contains(k) }
    zeroes.each |Str x| { verifyEq(u.trap(x, null), 0) }
    dim.each |Int v, Str x| { verifyEq(u.trap(x, null), v) }

    // verify additional parses are interned
    verifySame(Unit(s), u)
    verifySame(Unit(s), u)
    verifyErr(Err#) { Unit("$n; foobar") }
    verifyErr(Err#) { Unit("$n; $sym; m-33*A33") }

    // verify round trip
    verifySame(Unit(u.toStr), u)

    // verify dim ordering doesn't matter
    dimStr := dim.keys.sort.join("*") |Str k->Str| { return "$k${dim[k]}" }
    verifySame(Unit("$n;$sym;$dimStr;$scale;$offset"), u)

    // verify defined
    verify(Unit.list.contains(u))
    verifySame(Unit.find(n), u)
  }

//////////////////////////////////////////////////////////////////////////
// Database
//////////////////////////////////////////////////////////////////////////

  Void testDatabase()
  {
    m := Unit.find("meter")
    verifyEq(m.name, "meter")
    verifyEq(m.symbol, "m")
    verifyEq(m.m, 1)

    m3 := Unit.find("cubic_meter")
    verifyEq(m3.name, "cubic_meter")
    verifyEq(m3.symbol, "m\u00b3")
    verifyEq(m3.m, 3)

    all := Unit.list
    verifyType(all, Unit[]#)
    verify(all.contains(m))
    verify(all.contains(m3))

    quantities := Unit.quantities
    verify(quantities.size > 0)
    verify(quantities.isRO)
    verifyType(quantities, Str[]#)

    verify(quantities.contains("length"))
    verify(Unit.quantity("length").contains(m))

    verify(quantities.contains("volume"))
    verify(Unit.quantity("volume").contains(m3))
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  Void testConversionLength()
  {
    m  := Unit.find("meter")
    km := Unit.find("kilometer")
    mm := Unit.find("millimeter")
    in := Unit.find("inch")
    ft := Unit.find("foot")
    mi := Unit.find("mile")

    verifyConv(1f, m, 0.001f, km)
    verifyConv(1f, m, 1000f, mm)
    verifyConv(1f, m, 39.3700787f, in)
    verifyConv(1f, m, 3.2808399f, ft)
    verifyConv(1f, m, 0.000621371192f, mi)

    verifyConv(1000f, m, 1f, km)
    verifyConv(2f, km, 1.24274238f, mi)
    verifyConv(12f, in, 1f, ft)
    verifyConv(1f, mi, 5280f, ft)
    verifyConv(70f, mm, 2.75590551f, in)

    verifyErr(Err#) { verifyConv(60f, m, 1f, Unit.find("cubic_meter")) }
  }

  Void testConversionTime()
  {
    sec := Unit.find("second")
    min := Unit.find("minute")
    hr  := Unit.find("hour")

    verifyConv(60f, sec, 1f, min)
    verifyConv(60f, min, 1f, hr)
    verifyConv(2.5f, hr, 150f, min)

    verifyErr(Err#) { verifyConv(60f, sec, 1f, Unit.find("meter")) }
  }

  Void testConversionTemp()
  {
    k := Unit.find("kelvin")
    c := Unit.find("celsius")
    f := Unit.find("fahrenheit")

    verifyConv(0f, c, 273.15f, k)
    verifyConv(273.15f, k, 32f, f)
    verifyConv(0f, c, 32f, f)
    verifyConv(100f, c, 212f, f)
    verifyConv(75f, f, 23.88889f, c)
    verifyConv(37f, c, 98.6f, f)
  }

  Void verifyConv(Float from, Unit fromUnit, Float to, Unit toUnit)
  {
    actual := fromUnit.convertTo(from, toUnit)
    //echo("$from $fromUnit.symbol -> $to $toUnit.symbol ?= " + actual)
    verify(actual.approx(to))
  }

}