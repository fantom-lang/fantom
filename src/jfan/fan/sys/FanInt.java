//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor long into Long/FanInt
//
package fan.sys;

import fanx.serial.*;

/**
 * FanInt defines the methods for sys::Int
 *   sys::Int   =>  long primitive
 *   sys::Int?  =>  java.lang.Long
 */
public final class FanInt
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Long fromStr(String s) { return fromStr(s, Ten, true); }
  public static Long fromStr(String s, long radix) { return fromStr(s, radix, true); }
  public static Long fromStr(String s, long radix, boolean checked)
  {
    try
    {
      return Long.valueOf(s, (int)radix);
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("Int", s).val;
    }
  }

  public static long random() { return random(null); }
  public static long random(Range r)
  {
    long v = random.nextLong();
    if (r == null) return v;
    if (v < 0) v = -v;
    long start = r.start();
    long end   = r.end();
    if (r.inclusive()) ++end;
    return start + (v % (end-start));
  }
  static final java.util.Random random = new java.security.SecureRandom();

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static boolean equals(long self, Object obj)
  {
    if (obj instanceof Long)
      return self == ((Long)obj).longValue();
    else
      return false;
  }

  public static long compare(long self, Object obj)
  {
    long that = (Long)obj;
    if (self < that) return LT; return self == that ? EQ : GT;
  }

  public static long hash(long self)
  {
    return self;
  }

  public static Type type(long self)
  {
    return Sys.IntType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public static long negate(long self)
  {
    return -self;
  }

  public static long inverse(long self)
  {
    return ~self;
  }

  public static long mult(long self, long x)
  {
    return self * x;
  }

  public static long div(long self, long x)
  {
    return self / x;
  }

  public static long mod(long self, long x)
  {
    return self % x;
  }

  public static long plus(long self, long x)
  {
    return self + x;
  }

  public static long minus(long self, long x)
  {
    return self - x;
  }

  public static long and(long self, long x)
  {
    return self & x;
  }

  public static long or(long self, long x)
  {
    return self | x;
  }

  public static long xor(long self, long x)
  {
    return self ^ x;
  }

  public static long lshift(long self, long x)
  {
    return self << x;
  }

  public static long rshift(long self, long x)
  {
    return self >> x;
  }

  public static long increment(long self)
  {
    return self+1;
  }

  public static long decrement(long self)
  {
    return self-1;
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public static long abs(long self)
  {
    if (self >= 0) return self;
    return -self;
  }

  public static long min(long self, long that)
  {
    if (self <= that) return self;
    return that;
  }

  public static long max(long self, long that)
  {
    if (self >= that) return self;
    return that;
  }

  public static boolean isEven(long self)
  {
    return (self % 2) == 0;
  }

  public static boolean isOdd(long self)
  {
    return (self % 2) != 0;
  }

/////////////////////////////////////////////////////////////////////////
// Char
//////////////////////////////////////////////////////////////////////////


  public static boolean isSpace(long self)
  {
    try
    {
      return (self < 128 && (charMap[(int)self] & SPACE) != 0);
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static boolean isAlpha(long self)
  {
    try
    {
      return self < 128 && (charMap[(int)self] & (UPPER|LOWER)) != 0;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static boolean isAlphaNum(long self)
  {
    try
    {
      return (self < 128 && (charMap[(int)self] & (UPPER|LOWER|DIGIT)) != 0);
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static boolean isUpper(long self)
  {
    return 'A' <= self && self <= 'Z';
  }

  public static boolean isLower(long self)
  {
    return 'a' <= self && self <= 'z';
  }

  public static long upper(long self)
  {
    if ('a' <= self && self <= 'z')
      return self & ~0x20L;
    else
      return self;
  }

  public static long lower(long self)
  {
    if ('A' <= self && self <= 'Z')
      return self | 0x20L;
    else
      return self;
  }

  public static boolean isDigit(long self)
  {
    return '0' <= self && self <= '9';
  }

  public static boolean isDigit(long self, long r)
  {
    if (self < 0 || self >= 128) return false;

    int val = (int)self;
    int radix = (int)r;
    if (radix == 10)
    {
      return ((charMap[val] & DIGIT) != 0);
    }

    if (radix == 16)
    {
      return ((charMap[val] & HEX) != 0);
    }

    if (radix <= 10)
    {
      return '0' <= val && val <= ('0'+radix);
    }
    else
    {
      if ((charMap[val] & DIGIT) != 0) return true;
      int x = val-10;
      if ('a' <= val && val <= 'a'+x) return true;
      if ('A' <= val && val <= 'A'+x) return true;
      return false;
    }
  }

  public static Long toDigit(long self)
  {
    if (0 <= self && self <= 9) return pos[(int)self+ '0'];
    return null;
  }

  public static Long toDigit(long self, long radix)
  {
    if (self < 0 || self >= radix) return null;

    if (self < 10) return pos[(int)self + '0'];
    return pos[(int)self - 10 + 'a'];
  }

  public static Long fromDigit(long self)
  {
    if ('0' <= self && self <= '9') return pos[(int)self - '0'];
    return null;
  }

  public static Long fromDigit(long self, long r)
  {
    if (self < 0 || self >= 128) return null;
    int val = (int)self;

    int radix = (int)r;
    int ten = radix < 10 ? radix : 10;
    if ('0' <= val && val < '0'+ten) return pos[val - '0'];
    if (radix > 10)
    {
      int alpha = radix-10;
      if ('a' <= val && val < 'a'+alpha) return pos[val + 10 - 'a'];
      if ('A' <= val && val < 'A'+alpha) return pos[val + 10 - 'A'];
    }
    return null;
  }

  public static boolean equalsIgnoreCase(long self, long ch)
  {
    return (self | 0x20L) == (ch | 0x20L);
  }

  static final byte[] charMap = new byte[128];
  static final int SPACE = 0x01;
  static final int UPPER = 0x02;
  static final int LOWER = 0x04;
  static final int DIGIT = 0x08;
  static final int HEX   = 0x10;
  static
  {
    charMap[' ']  |= SPACE;
    charMap['\n'] |= SPACE;
    charMap['\r'] |= SPACE;
    charMap['\t'] |= SPACE;
    charMap['\f'] |= SPACE;

    // alpha characters
    for (int i='a'; i<='z'; ++i) charMap[i] |= LOWER;
    for (int i='A'; i<='Z'; ++i) charMap[i] |= UPPER;

    // digit characters
    for (int i='0'; i<='9'; ++i) charMap[i] |= DIGIT;

    // hex characters
    for (int i='0'; i<='9'; ++i) charMap[i] |= HEX;
    for (int i='a'; i<='f'; ++i) charMap[i] |= HEX;
    for (int i='A'; i<='F'; ++i) charMap[i] |= HEX;
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public static boolean localeIsUpper(long self)
  {
    return Character.isUpperCase((int)self);
  }

  public static boolean localeIsLower(long self)
  {
    return Character.isLowerCase((int)self);
  }

  public static long localeUpper(long self)
  {
    // Java doesn't provide a locale Character API
    return Character.toString((char)self).toUpperCase(Locale.current().java()).charAt(0);
  }

  public static long localeLower(long self)
  {
    // Java doesn't provide a locale Character API
    return Character.toString((char)self).toLowerCase(Locale.current().java()).charAt(0);
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toChar(long self)
  {
    if (self < 0 || self > 0xFFFF) throw Err.make("Invalid unicode char: " + self).val;
    if (self < FanStr.ascii.length) return FanStr.ascii[(int)self];
    return String.valueOf((char)self);
  }

  public static String toHex(long self) { return toHex(self, null); }
  public static String toHex(long self, Long width)
  {
    String s = Long.toHexString(self);
    if (width != null && s.length() < width.intValue())
      s = zeros[width.intValue()-s.length()] + s;
    return s;
  }
  static String[] zeros = new String[16];
  static { zeros[0] = ""; for (int i=1; i<zeros.length; ++i) zeros[i] = zeros[i-1] + "0"; }

  public static String toStr(long self)
  {
    return String.valueOf(self);
  }

//////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  public static void times(long self, Func f)
  {
    for (long i=0; i<self; ++i)
      f.call1(Long.valueOf(i));
  }

//////////////////////////////////////////////////////////////////////////
// Intern
//////////////////////////////////////////////////////////////////////////

  public static final long NEG = -257;
  public static final long POS = 4000;
  public static final long Zero;    // 0
  public static final long One;     // 1
  public static final long NegOne;  // -1
  public static final long NegTwo;  // -2
  public static final long Ten;     // 10
  public static final long LT;      // compare() -> -1
  public static final long EQ;      // compare() ->  0
  public static final long GT;      // compare() ->  1
  public static final long Chunk;   // 4kb / 4096
  public static final long maxValue = Long.MAX_VALUE;
  public static final long minValue = Long.MIN_VALUE;
//  static final Long[] neg = new Long[-(int)NEG];
  static final Long[] pos = new Long[(int)POS];

  static
  {
    for (int i=0; i<pos.length; ++i) pos[i] = Long.valueOf(i);
// TODO
    Zero   = Long.valueOf(0);
    One    = Long.valueOf(1);
    NegOne = Long.valueOf(-1);
    NegTwo = Long.valueOf(-2);
    Ten    = Long.valueOf(10);
    LT     = Long.valueOf(-1);
    EQ     = Long.valueOf(0);
    GT     = Long.valueOf(1);
    Chunk  = Long.valueOf(4096);
  }

}