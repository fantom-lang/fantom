//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//

**
** FloatTest
**
class FloatTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Is
//////////////////////////////////////////////////////////////////////////

  Void testIs()
  {
    Obj x := 3.0f
    verify(x.type === Float#)
    verify(x.isImmutable)

    verify(x is Obj)
    //verify(x is Num) TODO
    verify(x is Float)
    verifyFalse(x is Int)

    y := -4f
    verify(y.type === Float#)
    verify(y.isImmutable)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    Obj x := 3.0f

    verify(-2.0f == -2.0f)
    verify(0.0f == 0.0f)
    verify(15.0f == 0xf.toFloat)
    verify(1_000.4f == 1000.4f)
    verify(2.0f != 2.001f)
    verify(-2.0f != 0.0f)
    verify(-2.0f != 2.0f)
    verify(x != true)
    verify(5.0f != null)
    verify(null != -9e10f)

    verify(Float.posInf != 0.0f)
    verify(Float.posInf == Float.posInf)
    verify(Float.negInf != 0.0f)
    verify(Float.posInf != Float.negInf)
    verify(Float.negInf == Float.negInf)
    verify(Float.nan != 0.0f)
    verify(Float.nan != Float.posInf)
    verify(Float.nan != Float.negInf)
    verify(Float.nan == Float.nan)
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(2.0f < 3.0f)
    verify(null < 3.0f)
    verify(0.1f < Float.nan)
    verifyFalse(3.0f < 3.0f)
    verifyFalse(6.0f < 4.0f)
    verifyFalse(3.0f < null)

    verify(3.0f <= 3.0f)
    verify(3.0f <= 3.0f)
    verify(null <= 3f)
    verify(0.1f <= Float.nan)
    verify(Float.nan <= Float.nan)
    verify(Float.posInf <= Float.posInf)
    verifyFalse(6f <= 5f)
    verifyFalse(5f <= null)

    verify(-2f > -3f)
    verify(0f > -2f)
    verify(-2f > null)
    verify(Float.posInf > 1e17f)
    verify(Float.posInf > Float.negInf)
    verify(Float.nan > Float.posInf)
    verifyFalse(null > 77f)
    verifyFalse(3f > 4f)
    verifyFalse(0f >= Float.nan)

    verify(-3f >= -4f)
    verify(-3f >= -3f)
    verify(-3f >= null)
    verifyFalse(null >= 4f)
    verifyFalse(-3f >= -2f)
    verifyFalse(0f >= Float.nan)

    verifyEq(3f <=> 4f, -1)
    verifyEq(3f <=> 3f, 0)
    verifyEq(4f <=> 3f, 1)

    verifyEq(Float.posInf <=> 99f, 1)
    verifyEq(Float.posInf <=> Float.posInf, 0)
    verifyEq(Float.posInf <=> Float.negInf, 1)
    verifyEq(Float.negInf <=> 99f, -1)
    verifyEq(Float.negInf <=> 0f, -1)

    verifyEq(Float.nan <=> 0f, 1)
    verifyEq(Float.nan <=> Float.nan, 0)
    verifyEq(9e10f <=> Float.nan, -1)
    verifyEq(null <=> Float.nan, -1)
    verifyEq(Float.nan <=> null, 1)
    verifyEq(Float.posInf <=> Float.nan, -1)
    verifyEq(Float.negInf <=> Float.nan, -1)
    verifyEq(Float.nan <=> -9999f, 1)
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  Void testOperators()
  {
    Float x;
    x = 5f;   verifyEq(-x, -5f)
    x = -44f; verifyEq(-x, 44f)

    verifyEq(3f*2f,   6f)
    verifyEq(3f*-2f, -6f)
    verifyEq(-2f*3f, -6f)
    verifyEq(-3f*-2f, 6f)
    x=2f*2f; x*=3f; verifyEq(x, 12f)

    verifyEq(-16f/4f, -4f)
    verifyEq(16f / 5f, 3.2f)
    x = 20f / 2f; x /= -5f; verifyEq(x, -2f)

    verifyEq(21f%-6f, 3f)
    verifyEq(16f%5f, 1f)
    verifyEq(12f%5f, 2f)
    x = 19f % 10f; x %= 5f; verifyEq(x, 4f)

    verifyEq(2f + 3f,  5f)
    verifyEq(2f + -1f, 1f)
    x= 4f + 3f; x+=5f; verifyEq(x, 12f)

    verifyEq(7f - 3f,  4f)
    verifyEq(2f - 3f, -1f)
    x=5f - 2f; x-=-3.0f; verifyEq(x, 6f)
  }

  // TODO - need to fix when do const folding optimization
  // TODO - need to check field rvalues

//////////////////////////////////////////////////////////////////////////
// Increment
//////////////////////////////////////////////////////////////////////////

  Void testIncrement()
  {
    x:=4.0f
    verifyEq(++x, 5.0f); verifyEq(x, 5.0f)
    verifyEq(x++, 5.0f); verifyEq(x, 6.0f)
    verifyEq(--x, 5.0f); verifyEq(x, 5.0f)
    verifyEq(x--, 5.0f); verifyEq(x, 4.0f)
  }

//////////////////////////////////////////////////////////////////////////
// Num
//////////////////////////////////////////////////////////////////////////

  Void testNum()
  {
    verifyEq(3.0f.toInt, 3)
    verifyEq(((Num)3.1f).toInt, 3)
    verifyEq(3.9f.toInt, 3)
    verifyEq(4.0f.toInt, 4)
    verify(73939.9555f.toFloat === 73939.9555f)
    verifyEq(-5.66e12f.toDecimal <=> -5.66e12d, 0)
    verifyEq(Float.posInf.toInt, 0x7fff_ffff_ffff_ffff)
    verifyEq(Float.negInf.toInt, 0x8000_0000_0000_0000)
    verifyEq(Float.nan.toInt, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  Void testMath()
  {
    // mathematical constant
    verify(Float.e.approx(2.718281828459045f))
    verify(Float.pi.approx(3.141592653589793f))

    // abs
    verifyEq(3f.abs, 3f)
    verifyEq(0f.abs, 0f)
    verifyEq((-5.0f).abs, 5.0f)

    // min
    verifyEq(3f.min(2f), 2f)
    verifyEq((-7f).min(-7f), -7f)
    verifyEq(3f.min(5f), 3f)
    verifyEq(8f.min(-5f), -5f)

    // max
    verifyEq(0f.max(1f), 1f)
    verifyEq((-99.0f).max(-6666.0f), -99.0f)

    // ceil
    verifyEq(88f.ceil, 88f)
    verifyEq(6.335f.ceil, 7f)
    verifyEq(-3.3f.ceil, -4f)
    verifyEq(0.008f.ceil, 1f)

    // floor
    verifyEq(7f.floor, 7f)
    verifyEq(7.8523f.floor, 7f)
    verifyEq((-3.001f).floor, -4f)

    // round
    verifyEq(3.0f.round, 3.0f)
    verifyEq(3.1f.round, 3.0f)
    verifyEq(3.3f.round, 3.0f)
    verifyEq(3.4f.round, 3.0f)
    verifyEq(3.4999f.round, 3.0f)
    verifyEq(3.5f.round, 4.0f)
    verifyEq(3.6f.round, 4.0f)
    verifyEq(3.9f.round, 4.0f)
    verifyEq(4.0456e32f.round, 4.0456e32f)

    // exp
    verify(1f.exp.approx(Float.e))
    verify(2.5f.exp.approx(12.1824939607f))

    // log
    verify(Float.e.log.approx(1.0f))
    verify(1234.5678f.log.approx(7.1184762282977862925087925363871f))

    // log10
    verify(10f.log10.approx(1.0f))
    verify(0.00001f.log10.approx(-5.0f))

    // pow
    verifyEq(2f.pow(8f), 256.0f)
    verify(0.5f.pow(0.75f).approx(0.59460355750136053f))
    verifyEq(10f.pow(3f), 1000.0f)

    // sqrt
    verifyEq(25f.sqrt, 5.0f)
    verify(2.0f.sqrt.approx(1.414213562373f))
  }

//////////////////////////////////////////////////////////////////////////
// Trig
//////////////////////////////////////////////////////////////////////////

  Void testTrig()
  {
    // acos
    verify(0.6f.acos.approx(0.927295218001612f))

    // asin
    verify(0.5f.asin.approx(0.523598775598f))

    // atan
    verify(0.3f.atan.approx(0.29145679447786715f))

    // atan
    verify(Float.atan2(3f, 4f).approx(0.64350110879328f))

    // cos
    verify(Float.pi.cos.approx(-1.0f))
    verify(0.7f.cos.approx(0.7648421872844884262f))

    // cosh
    verify(0.7f.cosh.approx(1.25516900563f))

    // sin
    verify(Float.pi.sin.approx(0.0f, 1e-6f))
    verify(1.2f.sin.approx(0.9320390859672f))

    // sinh
    verify(1.2f.sinh.approx(1.50946135541217f))

    // tan
    verify(Float.pi.tan.approx(0.0f, 1e-6f))
    verify(0.25f.tan.approx(0.2553419212210362f))

    // tanh
    verify(0.3f.tanh.approx(0.29131261245159f))

    // toDegrees
    verify(Float.pi.toDegrees.approx(180.0f))
    verify(1f.toDegrees.approx(57.2957795f))

    // toRadians
    verify(90f.toRadians.approx(Float.pi/2.0f))
    verify(45f.toRadians.approx(0.785398163f))
  }

//////////////////////////////////////////////////////////////////////////
// Bits
//////////////////////////////////////////////////////////////////////////

  Void testBits()
  {
    verifyEq(0f.bits,   0)
    verifyEq(0f.bits32, 0)

    verifyEq(7.0f.bits,   0x401c000000000000)
    verifyEq(7.0f.bits32, 0x40e00000)

    verifyEq(0.007f.bits,   0x3f7cac083126e979)
    verifyEq(0.007f.bits32, 0x3be56042)

    verifyEq(3000000.0f.bits,   0x4146e36000000000)
    verifyEq(3000000.0f.bits32, 0x4a371b00)

    verifyEq((-1.0f).bits, 0xbff0000000000000)
    verifyEq((-1.0f).bits32, 0xbf800000)

    verifyEq((-7.05E-12f).bits, 0xbd9f019826e0ec8b)
    verifyEq((-7.05E-12f).bits32, 0xacf80cc1)

    floats := [0.0f, 88.0f, -7.432f, 123.56e18f, Float.posInf, Float.negInf, Float.nan]
    floats.each |Float r|
    {
      verifyEq(Float.makeBits(r.bits), r)
      verify(Float.makeBits32(r.bits32).approx(r))
    }
  }

//////////////////////////////////////////////////////////////////////////
// Approx
//////////////////////////////////////////////////////////////////////////

  Void testApprox()
  {
    verify(0f.approx(0f))
    verify(1e-10f.approx(0.0f, 1e-10f))
    verify(10f.approx(11f, 1f))
    verify(1000000f.approx(1000001f))
    verify(!1000000f.approx(1000002f))
    verify(Float.posInf.approx(Float.posInf))
    verify(Float.negInf.approx(Float.negInf))
    verify(Float.nan.approx(Float.nan))
  }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  Void testToStr()
  {
    verifyEq(Float.posInf.toStr, "INF")
    verifyEq(Float.negInf.toStr, "-INF")
    verifyEq(Float.nan.toStr,    "NaN")
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void testParse()
  {
    verifyEq(Float.fromStr("0"), 0.0f)
    verifyEq(Float.fromStr("0.8"), 0.8f)
    verifyEq(Float.fromStr("99.005"), 99.005f)
    verifyEq(Float.fromStr("INF"),  Float.posInf)
    verifyEq(Float.fromStr("-INF"), Float.negInf)
    verifyEq(Float.fromStr("NaN"),  Float.nan)
    verifyEq(Float.fromStr("foo", false),  null)
    verifyErr(ParseErr#) |,| { Float.fromStr("no way!") }
    verifyErr(ParseErr#) |,| { Float.fromStr("%\$##", true) }
  }

//////////////////////////////////////////////////////////////////////////
// Reflect
//////////////////////////////////////////////////////////////////////////

  Void testReflect()
  {
    verifyEq(Float#fromStr.call(["3.0"]), 3.0f)
    verifyEq(Float#fromStr.call1("3.0"), 3.0f)
    verifyEq(Float#fromStr.call2("xxx", false), null)

    verifyEq(Float#minus.call([5f, 3f]), 2f)
    verifyEq(Float#minus.call2(5f, 3f), 2f)
    verifyEq(Float#minus.callOn(5f, [3f]), 2f)
    verifyEq(Float#negate.callOn(5f, null), -5f)
  }

}