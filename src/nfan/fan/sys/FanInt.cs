//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//

using System;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// FanInt defines the methods for sys::Int.  The actual
  /// class used for representation is Fan.Sys.Int.
  /// </summary>
  public sealed class FanInt
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Long fromStr(string s) { return fromStr(s, 10, Boolean.True); }
    public static Long fromStr(string s, long radix) { return fromStr(s, radix, Boolean.True); }
    public static Long fromStr(string s, long radix, Boolean check)
    {
      try
      {
        return Long.valueOf(Convert.ToInt64(s, (int)radix));
      }
      catch (FormatException)
      {
        if (!check.booleanValue()) return null;
        throw ParseErr.make("Int", s).val;
      }
    }

    public static long random() { return random(null); }
    public static long random(Range r)
    {
      rand.GetBytes(randBytes);
      long v = BitConverter.ToInt64(randBytes, 0);
      if (r == null) return v;
      if (v < 0) v = -v;
      long start = r.start();
      long end   = r.end();
      if (r.inclusive().booleanValue()) ++end;
      return start + (v % (end-start));
    }

    static byte[] randBytes = new byte[8];
    static readonly System.Security.Cryptography.RNGCryptoServiceProvider
      rand = new System.Security.Cryptography.RNGCryptoServiceProvider();

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Boolean equals(long self, object obj)
    {
      if (obj is Long)
        return self == (obj as Long).longValue() ? Boolean.True : Boolean.False;
      else
        return Boolean.False;
    }

    public static long compare(long self, object obj)
    {
      long val = self;
      long that = ((long)obj);
      if (val < that) return -1; return val == that ? 0 : +1;
    }

    public static long hash(long self)
    {
      return self;
    }

    public static  Type type(long self)
    {
      return Sys.IntType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static long negate    (long self)         { return -self; }
    public static long inverse   (long self)         { return ~self; }
    public static long mult      (long self, long x) { return self * x; }
    public static long div       (long self, long x) { return self / x; }
    public static long mod       (long self, long x) { return self % x; }
    public static long plus      (long self, long x) { return self + x; }
    public static long minus     (long self, long x) { return self - x; }
    public static long and       (long self, long x) { return self & x; }
    public static long or        (long self, long x) { return self | x; }
    public static long xor       (long self, long x) { return self ^ x; }
    public static long lshift    (long self, long x) { return self << ((int)x); }
    public static long rshift    (long self, long x) { return self >> ((int)x); }
    public static long increment (long self)         { return self+1; }
    public static long decrement (long self)         { return self-1; }

  //////////////////////////////////////////////////////////////////////////
  // Math
  //////////////////////////////////////////////////////////////////////////

    public static long abs(long self)
    {
      long val = self;
      if (val >= 0) return self;
      return -val;
    }

    public static long min(long self, long that)
    {
      long val = self;
      if (val <= that) return self;
      return that;
    }

    public static long max(long self, long that)
    {
      long val = self;
      if (val >= that) return self;
      return that;
    }

    public static Boolean isEven(long self)
    {
      return (self % 2) == 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean isOdd(long self)
    {
      return (self % 2) != 0 ? Boolean.True : Boolean.False;
    }

  /////////////////////////////////////////////////////////////////////////
  // Char
  //////////////////////////////////////////////////////////////////////////

    public static Boolean isSpace(long self) { return Boolean.valueOf(isSpace((int)self)); }
    public static bool isSpace(int val)
    {
      try
      {
        return (val < 128 && (charMap[(int)val] & SPACE) != 0);
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static Boolean isAlpha(long self) { return Boolean.valueOf(isAlpha((int)self)); }
    public static bool isAlpha(int val)
    {
      try
      {
        return (val < 128 && (charMap[val] & (UPPER|LOWER)) != 0);
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static Boolean isAlphaNum(long self) { return Boolean.valueOf(isAlphaNum((int)self)); }
    public static bool isAlphaNum(int val)
    {
      try
      {
        if (val < 128 && (charMap[(int)val] & (UPPER|LOWER|DIGIT)) != 0)
          return true;
        else
          return false;
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static Boolean isUpper(long self)
    {
      long val = self;
      return 'A' <= val && val <= 'Z' ? Boolean.True : Boolean.False;
    }

    public static Boolean isLower(long self)
    {
      long val = self;
      return 'a' <= val && val <= 'z' ? Boolean.True : Boolean.False;
    }

    public static long upper(long self)
    {
      long val = self;
      if ('a' <= val && val <= 'z')
        return ((int)val) & ~0x20;
      else
        return self;
    }

    public static long lower(long self)
    {
      long val = self;
      if ('A' <= val && val <= 'Z')
        return ((int)val) | 0x20;
      else
        return self;
    }

    public static Boolean isDigit(long self)
    {
      long val = self;
      return '0' <= val && val <= '9' ? Boolean.True : Boolean.False;
    }

    public static Boolean isDigit(long self, long radix)
    {
      int val = (int)self;
      if (val < 0 || val >= 128) return Boolean.False;
      int r   = (int)radix;

      if (r == 10)
      {
        return ((charMap[val] & DIGIT) != 0) ? Boolean.True : Boolean.False;
      }

      if (r == 16)
      {
        return ((charMap[val] & HEX) != 0) ? Boolean.True : Boolean.False;
      }

      if (r <= 10)
      {
        return '0' <= val && val <= ('0'+r) ?  Boolean.True : Boolean.False;
      }
      else
      {
        if ((charMap[val] & DIGIT) != 0) return Boolean.True;
        int x = val-10;
        if ('a' <= val && val <= 'a'+x) return Boolean.True;
        if ('A' <= val && val <= 'A'+x) return Boolean.True;
        return Boolean.False;
      }
    }

    public static Long toDigit(long self)
    {
      long val = self;
      if (0 <= val && val <= 9) return Long.valueOf((int)val + '0');
      return null;
    }

    public static Long toDigit(long self, long radix)
    {
      int val = (int)self;
      int r   = (int)radix;
      if (val < 0 || val >= r) return null;

      if (val < 10) return Long.valueOf(val + '0');
      return Long.valueOf(val - 10 + 'a');
    }

    public static Long fromDigit(long self)
    {
      long val = self;
      if ('0' <= val && val <= '9') return Long.valueOf((int)val - '0');
      return null;
    }

    public static Long fromDigit(long self, long radix)
    {
      int val = (int)self;
      if (val < 0 || val >= 128) return null;
      int r   = (int)radix;

      int ten = r < 10 ? r : 10;
      if ('0' <= val && val < '0'+ten) return Long.valueOf(val - '0');
      if (r > 10)
      {
        int alpha = r-10;
        if ('a' <= val && val < 'a'+alpha) return Long.valueOf(val + 10 - 'a');
        if ('A' <= val && val < 'A'+alpha) return Long.valueOf(val + 10 - 'A');
      }
      return null;
    }

    public static Boolean equalsIgnoreCase(long self, long ch)
    {
      long val = self;
      return (val | 0x20L) == (ch | 0x20L) ? Boolean.True : Boolean.False;
    }

    internal static readonly byte[] charMap = new byte[128];
    internal static readonly byte SPACE = 0x01;
    internal static readonly byte UPPER = 0x02;
    internal static readonly byte LOWER = 0x04;
    internal static readonly byte DIGIT = 0x08;
    internal static readonly byte HEX   = 0x10;
    // static initializer below

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public static Boolean localeIsUpper(long self)
    {
      long val = self;
      return Char.IsUpper((char)val) ? Boolean.True : Boolean.False;
    }

    public static Boolean localeIsLower(long self)
    {
      long val = self;
      return Char.IsLower((char)val) ? Boolean.True : Boolean.False;
    }

    public static long localeUpper(long self)
    {
      long val = self;
      return Char.ToUpper((char)val, Locale.current().net());
    }

    public static long localeLower(long self)
    {
      long val = self;
      return Char.ToLower((char)val, Locale.current().net());
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static string toChar(long self)
    {
      long val = self;
      if (val < 0 || val > 0xFFFF) throw Err.make("Invalid unicode char: " + val).val;
      if (val < FanStr.m_ascii.Length) return FanStr.m_ascii[(int)val];
      return "" + (char)val;
    }

    public static string toHex(long self) { return toHex(self, null); }
    public static string toHex(long self, Long width)
    {
      long val = self;
      string s = val.ToString("X").ToLower();
      if (width != null && s.Length < width.intValue())
        s = zeros[width.intValue()-s.Length] + s;
      return s;
    }
    static string[] zeros = new string[16];

    public static string toStr(long self)
    {
      return self.ToString();
    }

    public static void encode(long self, ObjEncoder @out)
    {
      @out.w(self.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Closures
  //////////////////////////////////////////////////////////////////////////

    public static void times(long self, Func f)
    {
      long val = self;
      for (long i=0; i<val; i++)
        f.call1(i);
    }

  //////////////////////////////////////////////////////////////////////////
  // Intern
  //////////////////////////////////////////////////////////////////////////

    /// <summary>sys::Int.maxValue</summary>
    public static readonly long m_maxValue = Int64.MaxValue;

    /// <summary>sys::Int.maxValue</summary>
    public static readonly long m_minValue = Int64.MinValue;

    // default check size for IO buffering (defaults to 4KB)
    public const long Chunk = 4096;

    static FanInt()
    {
      charMap[' ']  |= SPACE;
      charMap['\n'] |= SPACE;
      charMap['\r'] |= SPACE;
      charMap['\t'] |= SPACE;
      charMap['\f'] |= SPACE;

      // alpha characters
      for (int i='a'; i<='z'; i++) charMap[i] |= LOWER;
      for (int i='A'; i<='Z'; i++) charMap[i] |= UPPER;

      // digit characters
      for (int i='0'; i<='9'; i++) charMap[i] |= DIGIT;

      // hex characters
      for (int i='0'; i<='9'; i++) charMap[i] |= HEX;
      for (int i='a'; i<='f'; i++) charMap[i] |= HEX;
      for (int i='A'; i<='F'; i++) charMap[i] |= HEX;

      // Zeros
      zeros[0] = "";
      for (int i=1; i<zeros.Length; ++i)
        zeros[i] = zeros[i-1] + "0";
    }

  }
}