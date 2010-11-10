//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//

using System;
using System.Globalization;
using System.Text;
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

    public static Long fromStr(string s) { return fromStr(s, 10, true); }
    public static Long fromStr(string s, long radix) { return fromStr(s, radix, true); }
    public static Long fromStr(string s, long radix, bool check)
    {
      try
      {
        return Long.valueOf(Convert.ToInt64(s, (int)radix));
      }
      catch (ArgumentException)
      {
        if (!check) return null;
        throw ParseErr.make("Int", s).val;
      }
      catch (OverflowException)
      {
        if (!check) return null;
        throw ParseErr.make("Int", s).val;
      }
      catch (FormatException)
      {
        if (!check) return null;
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
      if (r.inclusive()) ++end;
      if (end <= start) throw ArgErr.make("Range end < start: " + r).val;
      return start + (v % (end-start));
    }

    static byte[] randBytes = new byte[8];
    static readonly System.Security.Cryptography.RNGCryptoServiceProvider
      rand = new System.Security.Cryptography.RNGCryptoServiceProvider();

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static bool equals(long self, object obj)
    {
      if (obj is Long)
        return self == (obj as Long).longValue();
      else
        return false;
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

    public static long negate(long self) { return -self; }

    public static long increment(long self) { return self+1; }

    public static long decrement(long self) { return self-1; }

    public static long mult(long self, long x) { return self * x; }
    public static double multFloat(long self, double x) { return (double)self * x; }
    public static BigDecimal multDecimal(long self, BigDecimal x) { return BigDecimal.valueOf(self).multiply(x); }

    public static long div(long self, long x) { return self / x; }
    public static double divFloat(long self, double x) { return (double)self / x; }
    public static BigDecimal divDecimal(long self, BigDecimal x) { return BigDecimal.valueOf(self).divide(x); }

    public static long mod(long self, long x) { return self % x; }
    public static double modFloat(long self, double x) { return (double)self % x; }
    public static BigDecimal modDecimal(long self, BigDecimal x) { return BigDecimal.valueOf(self).remainder(x); }

    public static long plus(long self, long x) { return self + x; }
    public static double plusFloat(long self, double x) { return (double)self + x; }
    public static BigDecimal plusDecimal(long self, BigDecimal x) { return BigDecimal.valueOf(self).add(x); }

    public static long minus(long self, long x) { return self - x; }
    public static double minusFloat(long self, double x) { return (double)self - x; }
    public static BigDecimal minusDecimal(long self, BigDecimal x) { return BigDecimal.valueOf(self).subtract(x); }

  //////////////////////////////////////////////////////////////////////////
  // Bit-wise
  //////////////////////////////////////////////////////////////////////////

    public static long not       (long self)         { return ~self; }
    public static long and       (long self, long x) { return self & x; }
    public static long or        (long self, long x) { return self | x; }
    public static long xor       (long self, long x) { return self ^ x; }
    public static long shiftl    (long self, long x) { return self << ((int)x); }
    public static long shiftr    (long self, long x) { return (long)((ulong)self >> (int)x); }

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

    public static long pow(long self, long pow)
    {
      if (pow < 0) throw ArgErr.make("pow < 0").val;
      long result = 1;
      for (; pow>0; pow>>=1)
      {
        if ((pow&1) == 1) result *= self;
        self *= self;
      }
      return result;
    }

    public static bool isEven(long self)
    {
      return (self % 2) == 0;
    }

    public static bool isOdd(long self)
    {
      return (self % 2) != 0;
    }

  /////////////////////////////////////////////////////////////////////////
  // Char
  //////////////////////////////////////////////////////////////////////////

    public static bool isSpace(long self)
    {
      try
      {
        return (self < 128 && (charMap[(int)self] & SPACE) != 0);
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static bool isAlpha(long self)
    {
      try
      {
        return (self < 128 && (charMap[(int)self] & ALPHA) != 0);
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static bool isAlphaNum(long self)
    {
      try
      {
        return (self < 128 && (charMap[(int)self] & ALPHANUM) != 0);
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return false;
      }
    }

    public static bool isUpper(long self)
    {
      long val = self;
      return 'A' <= val && val <= 'Z';
    }

    public static bool isLower(long self)
    {
      long val = self;
      return 'a' <= val && val <= 'z';
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

    public static bool isDigit(long self)
    {
      long val = self;
      return '0' <= val && val <= '9';
    }

    public static bool isDigit(long self, long radix)
    {
      int val = (int)self;
      if (val < 0 || val >= 128) return false;
      int r   = (int)radix;

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
        int x = r - 10;
        if ('a' <= val && val < 'a'+x) return true;
        if ('A' <= val && val < 'A'+x) return true;
        return false;
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

    public static bool equalsIgnoreCase(long self, long ch)
    {
      if ('A' <= self && self <= 'Z') self |= 0x20;
      if ('A' <= ch   && ch   <= 'Z') ch   |= 0x20;
      return self == ch;
    }

    internal static readonly byte[] charMap = new byte[128];
    internal static readonly byte SPACE   = 0x01;
    internal static readonly byte UPPER   = 0x02;
    internal static readonly byte LOWER   = 0x04;
    internal static readonly byte DIGIT   = 0x08;
    internal static readonly byte HEX     = 0x10;
    internal static readonly int ALPHA    = UPPER | LOWER;
    internal static readonly int ALPHANUM = UPPER | LOWER | DIGIT;

    // static initializer below

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public static String toLocale(long self) { return toLocale(self, null); }
    public static String toLocale(long self, string pattern)
    {
      // if pattern is "B" format as bytes
      if (pattern != null && pattern.Length == 1 && pattern[0] == 'B')
        return toLocaleBytes(self);

      // get current locale
      Locale locale = Locale.cur();
      NumberFormatInfo df = locale.dec();

      // get default pattern if necessary
      if (pattern == null)
        pattern = Env.cur().locale(Sys.m_sysPod, "int", "#,###");

      // parse pattern and get digits
      NumPattern p = NumPattern.parse(pattern);
      NumDigits d = new NumDigits(self);

      // route to common FanNum method
      return FanNum.toLocale(p, d, df);
    }

    static string toLocaleBytes(long b)
    {
      if (b < KB)    return b + "B";
      if (b < 10*KB) return FanFloat.toLocale((double)b/KB, "#.#") + "KB";
      if (b < MB)    return Math.Round((double)b/KB) + "KB";
      if (b < 10*MB) return FanFloat.toLocale((double)b/MB, "#.#") + "MB";
      if (b < GB)    return Math.Round((double)b/MB) + "MB";
      if (b < 10*GB) return FanFloat.toLocale((double)b/GB, "#.#") + "GB";
      return Math.Round((double)b/GB) + "GB";
    }
    private static readonly long KB = 1024L;
    private static readonly long MB = 1024L*1024L;
    private static readonly long GB = 1024L*1024L*1024L;

    public static bool localeIsUpper(long self)
    {
      long val = self;
      return Char.IsUpper((char)val);
    }

    public static bool localeIsLower(long self)
    {
      long val = self;
      return Char.IsLower((char)val);
    }

    public static long localeUpper(long self)
    {
      long val = self;
      return Char.ToUpper((char)val, Locale.cur().dotnet());
    }

    public static long localeLower(long self)
    {
      long val = self;
      return Char.ToLower((char)val, Locale.cur().dotnet());
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
      {
        StringBuilder sb = new StringBuilder(width.intValue());
        int zeros = width.intValue() - s.Length;
        for (int i=0; i<zeros; ++i) sb.Append('0');
        sb.Append(s);
        s = sb.ToString();
      }
      return s;
    }

    public static string toStr(long self)
    {
      return self.ToString();
    }

    public static string toCode(long self) { return self.ToString(); }
    public static string toCode(long self, long b)
    {
      if (b == 10) return self.ToString();
      if (b == 16) return "0x" + toHex(self);
      throw ArgErr.make("Invalid base " + b).val;
    }

    public static void encode(long self, ObjEncoder @out)
    {
      @out.w(self.ToString());
    }

    public static Duration toDuration(long self) { return Duration.make(self); }

    public static DateTime toDateTime(long self) { return DateTime.makeTicks(self); }
    public static DateTime toDateTime(long self, TimeZone tz) { return DateTime.makeTicks(self, tz); }

  //////////////////////////////////////////////////////////////////////////
  // Closures
  //////////////////////////////////////////////////////////////////////////

    public static void times(long self, Func f)
    {
      long val = self;
      for (long i=0; i<val; i++)
        f.call(i);
    }

  //////////////////////////////////////////////////////////////////////////
  // Intern
  //////////////////////////////////////////////////////////////////////////

    /// <summary>sys::Int.maxValue</summary>
    public static readonly long m_maxVal = Int64.MaxValue;

    /// <summary>sys::Int.maxValue</summary>
    public static readonly long m_minVal = Int64.MinValue;

    /// <summary>sys::Int.defVal</summary>
    public static readonly long m_defVal = 0;

    // default check size for IO buffering (defaults to 4KB)
    public static readonly Long Chunk = Long.valueOf(4096);

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
    }

  }
}