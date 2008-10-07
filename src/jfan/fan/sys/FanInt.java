//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor Long into Long/FanInt
//
package fan.sys;

import fanx.serial.*;

/**
 * FanLong defines the methods for sys::Int.  The actual
 * class used for representation is java.lang.Long.
 */
public final class FanInt
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Long fromStr(String s) { return fromStr(s, Ten, true); }
  public static Long fromStr(String s, Long radix) { return fromStr(s, radix, true); }
  public static Long fromStr(String s, Long radix, Boolean checked)
  {
    try
    {
      return Long.valueOf(s, radix.intValue());
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("Int", s).val;
    }
  }

  public static Long random() { return random(null); }
  public static Long random(Range r)
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

  public static Boolean equals(Long self, Object obj)
  {
    if (obj instanceof Long)
      return self.longValue() == ((Long)obj).longValue();
    else
      return false;
  }

  public static Long compare(Long self, Object obj)
  {
    long val = self;
    long that = (Long)obj;
    if (val < that) return LT; return val == that ? EQ : GT;
  }

  public static Long hash(Long self)
  {
    return self;
  }

  public static Type type(Long self)
  {
    return Sys.IntType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public static Long negate(Long self)
  {
    return -self.longValue();
  }

  public static Long inverse(Long self)
  {
    return ~self.longValue();
  }

  public static Long mult(Long self, Long x)
  {
    return self.longValue() * x.longValue();
  }

  public static Long div(Long self, Long x)
  {
    return self.longValue() / x.longValue();
  }

  public static Long mod(Long self, Long x)
  {
    return self.longValue() % x.longValue();
  }

  public static Long plus(Long self, Long x)
  {
    return self.longValue() + x.longValue();
  }

  public static Long minus(Long self, Long x)
  {
    return self.longValue() - x.longValue();
  }

  public static Long and(Long self, Long x)
  {
    return self.longValue() & x.longValue();
  }

  public static Long or(Long self, Long x)
  {
    return self.longValue() | x.longValue();
  }

  public static Long xor(Long self, Long x)
  {
    return self.longValue() ^ x.longValue();
  }

  public static Long lshift(Long self, Long x)
  {
    return self.longValue() << x.longValue();
  }

  public static Long rshift(Long self, Long x)
  {
    return self.longValue() >> x.longValue();
  }

  public static Long increment(Long self)
  {
    return self.longValue()+1;
  }

  public static Long decrement(Long self)
  {
    return self.longValue()-1;
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public static Long abs(Long self)
  {
    long val = self;
    if (val >= 0) return self;
    return Long.valueOf(-val);
  }

  public static Long min(Long self, Long that)
  {
    long val = self;
    if (val <= that.longValue()) return self;
    return that;
  }

  public static Long max(Long self, Long that)
  {
    long val = self;
    if (val >= that.longValue()) return self;
    return that;
  }

  public static Boolean isEven(Long self)
  {
    long val = self;
    return (val % 2) == 0;
  }

  public static Boolean isOdd(Long self)
  {
    long val = self;
    return (val % 2) != 0;
  }

/////////////////////////////////////////////////////////////////////////
// Char
//////////////////////////////////////////////////////////////////////////


  public static Boolean isSpace(Long self) { return isSpace(self.intValue()); }
  public static boolean isSpace(int val)
  {
    try
    {
      return (val < 128 && (charMap[val] & SPACE) != 0);
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static Boolean isAlpha(Long self) { return isAlpha(self.intValue()); }
  public static boolean isAlpha(int val)
  {
    try
    {
      return val < 128 && (charMap[val] & (UPPER|LOWER)) != 0;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static Boolean isAlphaNum(Long self) { return isAlphaNum(self.intValue()); }
  public static boolean isAlphaNum(int val)
  {
    try
    {
      return (val < 128 && (charMap[val] & (UPPER|LOWER|DIGIT)) != 0);
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return false;
    }
  }

  public static Boolean isUpper(Long self)
  {
    long val = self;
    return 'A' <= val && val <= 'Z';
  }

  public static Boolean isLower(Long self)
  {
    long val = self;
    return 'a' <= val && val <= 'z';
  }

  public static Long upper(Long self)
  {
    long val = self;
    if ('a' <= val && val <= 'z')
      return pos[((int)val) & ~0x20];
    else
      return self;
  }

  public static Long lower(Long self)
  {
    long val = self;
    if ('A' <= val && val <= 'Z')
      return pos[((int)val) | 0x20];
    else
      return self;
  }

  public static Boolean isDigit(Long self)
  {
    long val = self;
    return '0' <= val && val <= '9';
  }

  public static Boolean isDigit(Long self, Long radix)
  {
    int val = self.intValue();
    if (val < 0 || val >= 128) return false;
    int r   = radix.intValue();

    if (r == 10)
    {
      return ((charMap[val] & DIGIT) != 0);
    }

    if (r == 16)
    {
      return ((charMap[val] & HEX) != 0);
    }

    if (r <= 10)
    {
      return '0' <= val && val <= ('0'+r);
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

  public static Long toDigit(Long self)
  {
    long val = self;
    if (0 <= val && val <= 9) return pos[(int)val + '0'];
    return null;
  }

  public static Long toDigit(Long self, Long radix)
  {
    int val = self.intValue();
    int r   = radix.intValue();
    if (val < 0 || val >= r) return null;

    if (val < 10) return pos[val + '0'];
    return pos[val - 10 + 'a'];
  }

  public static Long fromDigit(Long self)
  {
    long val = self;
    if ('0' <= val && val <= '9') return pos[(int)val - '0'];
    return null;
  }

  public static Long fromDigit(Long self, Long radix)
  {
    int val = self.intValue();
    if (val < 0 || val >= 128) return null;
    int r   = radix.intValue();

    int ten = r < 10 ? r : 10;
    if ('0' <= val && val < '0'+ten) return pos[val - '0'];
    if (r > 10)
    {
      int alpha = r-10;
      if ('a' <= val && val < 'a'+alpha) return pos[val + 10 - 'a'];
      if ('A' <= val && val < 'A'+alpha) return pos[val + 10 - 'A'];
    }
    return null;
  }

  public static Boolean equalsIgnoreCase(Long self, Long ch)
  {
    long val = self;
    return (val | 0x20L) == (ch.longValue() | 0x20L);
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

  public static Boolean localeIsUpper(Long self)
  {
    return Character.isUpperCase(self.intValue());
  }

  public static Boolean localeIsLower(Long self)
  {
    return Character.isLowerCase(self.intValue());
  }

  public static Long localeUpper(Long self)
  {
    // Java doesn't provide a locale Character API
    long val = self.longValue();
    return Long.valueOf(Character.toString((char)val).toUpperCase(Locale.current().java()).charAt(0));
  }

  public static Long localeLower(Long self)
  {
    // Java doesn't provide a locale Character API
    long val = self.longValue();
    return Long.valueOf(Character.toString((char)val).toLowerCase(Locale.current().java()).charAt(0));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toChar(Long self)
  {
    long val = self;
    if (val < 0 || val > 0xFFFF) throw Err.make("Invalid unicode char: " + val).val;
    if (val < FanStr.ascii.length) return FanStr.ascii[(int)val];
    return String.valueOf((char)val);
  }

  public static String toHex(Long self) { return toHex(self, null); }
  public static String toHex(Long self, Long width)
  {
    long val = self.longValue();
    String s = Long.toHexString(val);
    if (width != null && s.length() < width.intValue())
      s = zeros[width.intValue()-s.length()] + s;
    return s;
  }
  static String[] zeros = new String[16];
  static { zeros[0] = ""; for (int i=1; i<zeros.length; ++i) zeros[i] = zeros[i-1] + "0"; }

  public static String toStr(Long self)
  {
    return self.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  public static void times(Long self, Func f)
  {
    long val = self;
    for (long i=0; i<val; ++i)
      f.call1(Long.valueOf(i));
  }

//////////////////////////////////////////////////////////////////////////
// Intern
//////////////////////////////////////////////////////////////////////////

  public static final long NEG = -257;
  public static final long POS = 4000;
  public static final Long Zero;    // 0
  public static final Long One;     // 1
  public static final Long NegOne;  // -1
  public static final Long NegTwo;  // -2
  public static final Long Ten;     // 10
  public static final Long LT;      // compare() -> -1
  public static final Long EQ;      // compare() ->  0
  public static final Long GT;      // compare() ->  1
  public static final Long Chunk;   // 4kb / 4096
  public static final Long maxValue = Long.valueOf(Long.MAX_VALUE);
  public static final Long minValue = Long.valueOf(Long.MIN_VALUE);
  static final Long[] neg = new Long[-(int)NEG];
  static final Long[] pos = new Long[(int)POS];

  static
  {
    for (int i=1; i<neg.length; ++i) neg[i] = Long.valueOf(-i);
    for (int i=0; i<pos.length; ++i) pos[i] = Long.valueOf(i);
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