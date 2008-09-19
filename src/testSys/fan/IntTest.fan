//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 06  Brian Frank  Creation
//

**
** IntTest
**
class IntTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  Void testConstants()
  {
    verifyEq(Int.maxValue, 9223372036854775807)
    verifyEq(Int.minValue, -9223372036854775807-1)
  }

//////////////////////////////////////////////////////////////////////////
// Is
//////////////////////////////////////////////////////////////////////////

  Void testIs()
  {
    Obj x := 3

    verify(x.type === Int#)

    verify(x is Obj)
    verify(x is Num)
    verify(x is Int)
    verifyFalse(x is Float)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    verify(-2 == -2)
    verify(0 == 0)
    verify(15 == 0xf)
    verify(1_000 == 1000)
    verify(0xABCD == 0xabcd)
    verify(0xffff_ffff_ffff_ffff == 0xffff_ffff_ffff_ffff)
    verify(2 != 3)
    verify(-2 != 0)
    verify(3 as Obj != "foo")
    verify(0 != null)
    verify(null != 99)
  }

//////////////////////////////////////////////////////////////////////////
// Same
//////////////////////////////////////////////////////////////////////////

  Void testSame()
  {
    verify(0 === 0)
    verify(4 === 4)
    verify('z' === 'z')
    verify('z' !== 'Z')

    // everything from -256 to 1024 must be interned to use ===
    j := -256
    for (Int i := -256; i<=1024; ++i)
    {
      verifySame(i, j)
      j++
    }

    // technically this would be ok in an implementation, but
    // it's more to just test CompareNotSame than anything
    x := 100_000
    y :=  99_999
    verify(x !== y+1)
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(2 < 3)
    verify(null < 3)
    verifyFalse(3 < 3)
    verifyFalse(6 < 4)
    verifyFalse(3 < null)

    verify(3 <= 3)
    verify(3 <= 3)
    verify(null <= 3)
    verifyFalse(6 <= 5)
    verifyFalse(5 <= null)

    verify(-2 > -3)
    verify(0 > -2)
    verify(-2 > null)
    verifyFalse(null > 77)
    verifyFalse(3 > 4)

    verify(-3 >= -4)
    verify(-3 >= -3)
    verify(-3 >= null)
    verifyFalse(null >= 4)
    verifyFalse(-3 >= -2)

    verifyEq(3 <=> 4, -1)
    verifyEq(3 <=> 3, 0)
    verifyEq(4 <=> 3, 1)
    verifyEq(null <=> 3, -1)
    verifyEq(null <=> null, 0)
    verifyEq(-9 <=> null, 1)
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  Void testOperators()
  {
    Int x;
    x = 5;   verifyEq(-x, -5)
    x = -44; verifyEq(-x, 44)

    verifyEq(3*2,   6)
    verifyEq(3*-2, -6)
    verifyEq(-2*3, -6)
    verifyEq(-3*-2, 6)
    x=2*2; x*=3; verifyEq(x, 12)

    verifyEq(-16/4, -4)
    verifyEq(16 / 5, 3)
    x = 20 / 2; x /= -5; verifyEq(x, -2)

    verifyEq(21%-6, 3)
    verifyEq(16%5, 1)
    verifyEq(12%5, 2)
    x = 19 % 10; x %= 5; verifyEq(x, 4)

    verifyEq(2 + 3,  5)
    verifyEq(2 + -1, 1)
    verifyEq(2+3,  5)
    verifyEq(2+-1, 1)
    x= 4 + 3; x+=5; verifyEq(x, 12)

    verifyEq(7 - 3,  4)
    verifyEq(2 - 3, -1)
    verifyEq(7-3,  4)
    verifyEq(2-3, -1)
    x=5 - 2; x-=-3; verifyEq(x, 6)
  }

  // TODO - need to fix when do const folding optimization
  // TODO - need to check field rvalues

//////////////////////////////////////////////////////////////////////////
// Increment
//////////////////////////////////////////////////////////////////////////

  Void testIncrement()
  {
    x:=4
    verifyEq(++x, 5); verifyEq(x, 5)
    verifyEq(x++, 5); verifyEq(x, 6)
    verifyEq(--x, 5); verifyEq(x, 5)
    verifyEq(x--, 5); verifyEq(x, 4)
  }

//////////////////////////////////////////////////////////////////////////
// Bitwise
//////////////////////////////////////////////////////////////////////////

  Void testBitwise()
  {
    x := 0xffff;
    verifyEq(0xff & 0x0f, 0x0f)
    verifyEq(0xf1 & 0x0f, 0x01)
    verifyEq(0xa0 | 0x0b, 0xab)
    verifyEq(0x03 ^ 0x02, 0x01)
    verifyEq(0xff ^ 0x17, 0xe8)
    verifyEq(0x01 << 1, 0x02)
    verifyEq(0x0a << 4, 0xa0)
    verifyEq(0x80 >> 1, 0x40)
    verifyEq(0x80 >> 3, 0x10)
  }

//////////////////////////////////////////////////////////////////////////
// Num
//////////////////////////////////////////////////////////////////////////

  Void testNum()
  {
    verifyEq(9.toFloat, 9.0f)
    verifyEq(9.toDecimal, 9d)
    verifyEq(-123456789.toDecimal, -123456789d)
    verifyEq(-7.toInt, -7)
    verify(93757393754.toInt === 93757393754)
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  Void testMath()
  {
    verifyEq(3.abs, 3)
    verifyEq(0.abs, 0)
    verifyEq((-5).abs, 5)

    verifyEq(3.min(2), 2)
    verifyEq((-7).min(-7), -7)
    verifyEq(3.min(5), 3)
    verifyEq(8.min(-5), -5)

    verifyEq(0.max(1), 1)
    verifyEq((-99).max(-6666), -99)
    verifyEq('a'.max(' '), 'a')

    verifyEq((-2).isEven,    true)
    verifyEq((-1).isEven,    false)
    verifyEq(0.isEven,       true)
    verifyEq(1.isEven,       false)
    verifyEq(2.isEven,       true)
    verifyEq(140_806.isEven, true)
    verifyEq((-2).isOdd,     false)
    verifyEq(0.isOdd,        false)
    verifyEq(1.isOdd,        true)
    verifyEq(77.isOdd,       true)
  }

//////////////////////////////////////////////////////////////////////////
// Char Test
//////////////////////////////////////////////////////////////////////////

  Void testCharTests()
  {
    verifyChar(' ',  "s")
    verifyChar('\t', "s")
    verifyChar('\n', "s")
    verifyChar('\r', "s")

    for (Int c := 'A'; c <= 'F'; ++c) verifyChar(c, "auh")
    for (Int c := 'a'; c <= 'f'; ++c) verifyChar(c, "alh")
    for (Int c := 'G'; c <= 'Z'; ++c) verifyChar(c, "au")
    for (Int c := 'g'; c <= 'z'; ++c) verifyChar(c, "al")
    for (Int c := '0'; c <= '9'; ++c) verifyChar(c, "dh")

    symbols := "`~!@#%^&*()-_=+[]{}\\|;:'\"<>?,./\u007F\u00FF\u01cc"
    symbols.each |Int ch| { verifyChar(ch, "") }

    verifyChar(-1, "")

    verifyEq('1'.isDigit(2), true)
    verifyEq('3'.isDigit(2), false)

    verifyEq('g'.isDigit(17), true)
    verifyEq('g'.isDigit(16), false)
    verifyEq('G'.isDigit(17), true)
    verifyEq('G'.isDigit(16), false)
  }

  Void verifyChar(Int char, Str pattern)
  {
    verifyEq(char.isSpace,     pattern.contains("s"))
    verifyEq(char.isDigit,     pattern.contains("d"))
    verifyEq(char.isDigit(16), pattern.contains("h"))
    verifyEq(char.isAlpha,     pattern.contains("a"))
    verifyEq(char.isUpper,     pattern.contains("u"))
    verifyEq(char.isLower,     pattern.contains("l"))
  }

//////////////////////////////////////////////////////////////////////////
// Char Conv
//////////////////////////////////////////////////////////////////////////

  Void testCharConv()
  {
    // upper
    verifyEq('a'.upper, 'A')
    verifyEq('z'.upper, 'Z')
    verifyEq('G'.upper, 'G')
    verifyEq('3'.upper, '3')
    verifyEq(999.upper, 999)
    verifyEq((-6).upper, -6)

    // lower
    verifyEq('A'.lower, 'a')
    verifyEq('Z'.lower, 'z')
    verifyEq('i'.lower, 'i')
    verifyEq((-88).lower, -88)

    // ensure locale doesn't work for ASCII methods
    Locale.fromStr("tr").with |,|
    {
      verifyEq('I'.lower, 'i')
      verifyEq('i'.upper, 'I')
    }

    // toDigit - decimal
    verifyEq((-1).toDigit, null)
    verifyEq(0.toDigit, '0')
    verifyEq(3.toDigit, '3')
    verifyEq(9.toDigit, '9')
    verifyEq(10.toDigit, null)
    verifyEq((-1).toDigit(10), null)
    verifyEq(0.toDigit(10), '0')
    verifyEq(3.toDigit(10), '3')
    verifyEq(9.toDigit(10), '9')
    verifyEq(10.toDigit(10), null)

    // toDigit - hex
    verifyEq(' '.toDigit(16), null)
    verifyEq(0.toDigit(16), '0')
    verifyEq(9.toDigit(16), '9')
    verifyEq(10.toDigit(16), 'a')
    verifyEq(15.toDigit(16), 'f')
    verifyEq(17.toDigit(16), null)
    verifyEq(99.toDigit(16), null)

    // toDigit - base36
    verifyEq(0.toDigit(36), '0')
    verifyEq(9.toDigit(36), '9')
    verifyEq(15.toDigit(36), 'f')
    verifyEq(35.toDigit(36), 'z')
    verifyEq(36.toDigit(36), null)

    // toDigit - binary
    verifyEq((-1).toDigit(2), null)
    verifyEq(0.toDigit(2), '0')
    verifyEq(1.toDigit(2), '1')
    verifyEq(2.toDigit(2), null)

    // fromDigit - decimal
    verifyEq(' '.fromDigit, null)
    verifyEq('0'.fromDigit, 0)
    verifyEq('3'.fromDigit, 3)
    verifyEq('9'.fromDigit, 9)
    verifyEq('a'.fromDigit, null)
    verifyEq(' '.fromDigit(10), null)
    verifyEq('0'.fromDigit(10), 0)
    verifyEq('3'.fromDigit(10), 3)
    verifyEq('9'.fromDigit(10), 9)
    verifyEq('a'.fromDigit(10), null)

    // fromDigit - hex
    verifyEq('0'.fromDigit(16), 0)
    verifyEq('9'.fromDigit(16), 9)
    verifyEq('a'.fromDigit(16), 0xa)
    verifyEq('f'.fromDigit(16), 0xf)
    verifyEq('g'.fromDigit(16), null)
    verifyEq('A'.fromDigit(16), 0xa)
    verifyEq('F'.fromDigit(16), 0xf)
    verifyEq('G'.fromDigit(16), null)
    verifyEq(3.fromDigit(16), null)

    // fromDigit - base36
    verifyEq(' '.fromDigit(36), null)
    verifyEq('5'.fromDigit(36), 5)
    verifyEq('c'.fromDigit(36), 12)
    verifyEq('Z'.fromDigit(36), 35)
    verifyEq('['.fromDigit(36), null)
    verifyEq('z'.fromDigit(36), 35)
    verifyEq('{'.fromDigit(36), null)

    // fromDigit - binary
    verifyEq('0'.fromDigit(2), 0)
    verifyEq('1'.fromDigit(2), 1)
    verifyEq('2'.fromDigit(2), null)
  }

//////////////////////////////////////////////////////////////////////////
// EqualsIgnoreCase
//////////////////////////////////////////////////////////////////////////

  Void testEqualsIgnoreCase()
  {
    verifyEq('a'.equalsIgnoreCase('a'), true)
    verifyEq('a'.equalsIgnoreCase('b'), false)
    verifyEq('a'.equalsIgnoreCase('A'), true)
    verifyEq('Z'.equalsIgnoreCase('z'), true)
    verifyEq('Z'.equalsIgnoreCase('!'), false)
    Locale.fromStr("tr").with |,|
    {
      verifyEq('I'.equalsIgnoreCase('i'), true)
      verifyEq('i'.equalsIgnoreCase('I'), true)
    }
  }

//////////////////////////////////////////////////////////////////////////
// ToChar
//////////////////////////////////////////////////////////////////////////

  Void testToChar()
  {
    verifyEq(97.toChar, "a")
    verifyEq(32.toChar, " ")
    verifyEq(0x1234.toChar, "\u1234")

    verifyErr(Err#) |,| { 0x10000.toChar }
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  Void testLocale()
  {
    verifyLocale("en", 'a', 'a', 'A')
    verifyLocale("en", 'i', 'i', 'I')
    verifyLocale("en", 'Z', 'z', 'Z')

    verifyLocale("en", '\u0391', '\u03b1', '\u0391') // Greek A
    verifyLocale("el", '\u03c9', '\u03c9', '\u03a9') // Greek Omega
    verifyLocale("sk", '\u0414', '\u0434', '\u0414') // Cryllic DE
    verifyLocale("tr", 'i', 'i', '\u0130')           // Turkish dotted i
    verifyLocale("tr", 'I', '\u0131', 'I')           // Turkish undotted I
  }

  Void verifyLocale(Str locale, Int c, Int lower, Int upper)
  {
    Locale.fromStr(locale).with |,|
    {
      verifyEq(c.localeIsLower, c == lower)
      verifyEq(c.localeIsUpper, c == upper)
      verifyEq(c.localeLower,   lower)
      verifyEq(c.localeUpper,   upper)
      verifyEq(c.localeLower.localeUpper, upper)
      verifyEq(c.localeUpper.localeLower, lower)
    }
  }

//////////////////////////////////////////////////////////////////////////
// ToHex
//////////////////////////////////////////////////////////////////////////

  Void testToHex()
  {
    verifyEq(255.toHex, "ff")
    verifyEq(255.toHex(4), "00ff")
    verifyEq(0x123456789abcdef.toHex, "123456789abcdef")
    verifyEq(0x123456789abcdef.toHex(18), "000123456789abcdef")
    verifyEq(0.toHex(10), "0000000000")
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void testParse()
  {
    verifyEq(Int.fromStr("0"), 0)
    verifyEq(Int.fromStr("-1"), -1)
    verifyEq(Int.fromStr("999"), 999)
    verifyEq(Int.fromStr("1234567890"), 1234567890)
    verifyEq(Int.fromStr("10", 16), 0x10)
    verifyEq(Int.fromStr("abcdef", 16), 0xabcdef)
    verifyEq(Int.fromStr("AbCdEf", 16), 0xabcdef)
    verifyEq(Int.fromStr("77", 10, true), 77)
    verifyEq(Int.fromStr("x", 10, false), null)
    verifyErr(ParseErr#) |,| { Int.fromStr("x") }
    verifyErr(ParseErr#) |,| { Int.fromStr("3", 2, true) }
  }

//////////////////////////////////////////////////////////////////////////
// Random
//////////////////////////////////////////////////////////////////////////

  Void testRandom()
  {
    acc := Int:Obj[:]
    10.times |,| { acc.set(Int.random, this) }
    verifyEq(acc.size, 10)

    acc.clear
    1000.times |,|
    {
      i := Int.random(0..10)
      verify((0..10).contains(i))
      acc.set(i, this)
    }
    verifyEq(acc.size, 11)

    acc.clear
    1000.times |,|
    {
      i := Int.random(10...20)
      verify((10...20).contains(i))
      acc.set(i, this)
    }
    verifyEq(acc.size, 10)

  }

}