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

    public static Long fromStr(Str s) { return fromStr(s, Ten, Boolean.True); }
    public static Long fromStr(Str s, Long radix) { return fromStr(s, radix, Boolean.True); }
    public static Long fromStr(Str s, Long radix, Boolean check)
    {
      try
      {
        return Long.valueOf(Convert.ToInt64(s.val, radix.intValue()));
      }
      catch (FormatException)
      {
        if (!check.booleanValue()) return null;
        throw ParseErr.make("Long", s).val;
      }
    }

    public static Long random() { return random(null); }
    public static Long random(Range r)
    {
      rand.GetBytes(randBytes);
      long v = BitConverter.ToInt64(randBytes, 0);
      if (r == null) return Long.valueOf(v);
      if (v < 0) v = -v;
      long start = r.start().longValue();
      long end   = r.end().longValue();
      if (r.inclusive().booleanValue()) ++end;
      return Long.valueOf(start + (v % (end-start)));
    }

    static byte[] randBytes = new byte[8];
    static readonly System.Security.Cryptography.RNGCryptoServiceProvider
      rand = new System.Security.Cryptography.RNGCryptoServiceProvider();

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Boolean equals(Long self, object obj)
    {
      if (obj is Long)
        return self.longValue() == ((Long)obj).longValue() ? Boolean.True : Boolean.False;
      else
        return Boolean.False;
    }

    public static Long compare(Long self, object obj)
    {
      long val = self.longValue();
      long that = ((Long)obj).longValue();
      if (val < that) return LT; return val == that ? EQ : GT;
    }

    public static Long hash(Long self)
    {
      return self;
    }

    public static  Type type(Long self)
    {
      return Sys.IntType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static Long negate    (Long self)         { return Long.valueOf(-self.longValue()); }
    public static Long inverse   (Long self)         { return Long.valueOf(~self.longValue()); }
    public static Long mult      (Long self, Long x) { return Long.valueOf(self.longValue() * x.longValue()); }
    public static Long div       (Long self, Long x) { return Long.valueOf(self.longValue() / x.longValue()); }
    public static Long mod       (Long self, Long x) { return Long.valueOf(self.longValue() % x.longValue()); }
    public static Long plus      (Long self, Long x) { return Long.valueOf(self.longValue() + x.longValue()); }
    public static Long minus     (Long self, Long x) { return Long.valueOf(self.longValue() - x.longValue()); }
    public static Long and       (Long self, Long x) { return Long.valueOf(self.longValue() & x.longValue()); }
    public static Long or        (Long self, Long x) { return Long.valueOf(self.longValue() | x.longValue()); }
    public static Long xor       (Long self, Long x) { return Long.valueOf(self.longValue() ^ x.longValue()); }
    public static Long lshift    (Long self, Long x) { return Long.valueOf(self.longValue() << (int)x.longValue()); }
    public static Long rshift    (Long self, Long x) { return Long.valueOf(self.longValue() >> (int)x.longValue()); }
    public static Long increment (Long self)         { return Long.valueOf(self.longValue()+1); }
    public static Long decrement (Long self)         { return Long.valueOf(self.longValue()-1); }

  //////////////////////////////////////////////////////////////////////////
  // Math
  //////////////////////////////////////////////////////////////////////////

    public static Long abs(Long self)
    {
      long val = self.longValue();
      if (val >= 0) return self;
      return Long.valueOf(-val);
    }

    public static Long min(Long self, Long that)
    {
      long val = self.longValue();
      if (val <= that.longValue()) return self;
      return that;
    }

    public static Long max(Long self, Long that)
    {
      long val = self.longValue();
      if (val >= that.longValue()) return self;
      return that;
    }

    public static Boolean isEven(Long self)
    {
      return (self.longValue() % 2) == 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean isOdd(Long self)
    {
      return (self.longValue() % 2) != 0 ? Boolean.True : Boolean.False;
    }

  /////////////////////////////////////////////////////////////////////////
  // Char
  //////////////////////////////////////////////////////////////////////////

    public static Boolean isSpace(Long self) { return Boolean.valueOf(isSpace(self.intValue())); }
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

    public static Boolean isAlpha(Long self) { return Boolean.valueOf(isAlpha(self.intValue())); }
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

    public static Boolean isAlphaNum(Long self) { return Boolean.valueOf(isAlphaNum(self.intValue())); }
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

    public static Boolean isUpper(Long self)
    {
      long val = self.longValue();
      return 'A' <= val && val <= 'Z' ? Boolean.True : Boolean.False;
    }

    public static Boolean isLower(Long self)
    {
      long val = self.longValue();
      return 'a' <= val && val <= 'z' ? Boolean.True : Boolean.False;
    }

    public static Long upper(Long self)
    {
      long val = self.longValue();
      if ('a' <= val && val <= 'z')
        return m_pos[((int)val) & ~0x20];
      else
        return self;
    }

    public static Long lower(Long self)
    {
      long val = self.longValue();
      if ('A' <= val && val <= 'Z')
        return m_pos[((int)val) | 0x20];
      else
        return self;
    }

    public static Boolean isDigit(Long self)
    {
      long val = self.longValue();
      return '0' <= val && val <= '9' ? Boolean.True : Boolean.False;
    }

    public static Boolean isDigit(Long self, Long radix)
    {
      int val = self.intValue();
      if (val < 0 || val >= 128) return Boolean.False;
      int r   = radix.intValue();

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

    public static Long toDigit(Long self)
    {
      long val = self.longValue();
      if (0 <= val && val <= 9) return m_pos[(int)val + '0'];
      return null;
    }

    public static Long toDigit(Long self, Long radix)
    {
      int val = self.intValue();
      int r   = radix.intValue();
      if (val < 0 || val >= r) return null;

      if (val < 10) return m_pos[val + '0'];
      return m_pos[val - 10 + 'a'];
    }

    public static Long fromDigit(Long self)
    {
      long val = self.longValue();
      if ('0' <= val && val <= '9') return m_pos[(int)val - '0'];
      return null;
    }

    public static Long fromDigit(Long self, Long radix)
    {
      int val = self.intValue();
      if (val < 0 || val >= 128) return null;
      int r   = radix.intValue();

      int ten = r < 10 ? r : 10;
      if ('0' <= val && val < '0'+ten) return m_pos[val - '0'];
      if (r > 10)
      {
        int alpha = r-10;
        if ('a' <= val && val < 'a'+alpha) return m_pos[val + 10 - 'a'];
        if ('A' <= val && val < 'A'+alpha) return m_pos[val + 10 - 'A'];
      }
      return null;
    }

    public static Boolean equalsIgnoreCase(Long self, Long ch)
    {
      long val = self.longValue();
      return (val | 0x20L) == (ch.longValue() | 0x20L) ? Boolean.True : Boolean.False;
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

    public static Boolean localeIsUpper(Long self)
    {
      long val = self.longValue();
      return Char.IsUpper((char)val) ? Boolean.True : Boolean.False;
    }

    public static Boolean localeIsLower(Long self)
    {
      long val = self.longValue();
      return Char.IsLower((char)val) ? Boolean.True : Boolean.False;
    }

    public static Long localeUpper(Long self)
    {
      long val = self.longValue();
      return Long.valueOf(Char.ToUpper((char)val, Locale.current().net()));
    }

    public static Long localeLower(Long self)
    {
      long val = self.longValue();
      return Long.valueOf(Char.ToLower((char)val, Locale.current().net()));
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static Str toChar(Long self)
    {
      long val = self.longValue();
      if (val < 0 || val > 0xFFFF) throw Err.make("Invalid unicode char: " + val).val;
      if (val < Str.m_ascii.Length) return Str.m_ascii[(int)val];
      return Str.make("" + (char)val);
    }

    public static Str toHex(Long self) { return toHex(self, null); }
    public static Str toHex(Long self, Long width)
    {
      long val = self.longValue();
      string s = val.ToString("X").ToLower();
      if (width != null && s.Length < width.intValue())
        s = zeros[(int)width.intValue()-s.Length] + s;
      return Str.make(s);
    }
    static string[] zeros = new string[16];

    public static Str toStr(Long self)
    {
      return Str.make(self.ToString());
    }

    public static void encode(Long self, ObjEncoder @out)
    {
      @out.w(self.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Closures
  //////////////////////////////////////////////////////////////////////////

    public static void times(Long self, Func f)
    {
      long val = self.longValue();
      for (long i=0; i<val; i++)
        f.call1(Long.valueOf(i));
    }

  //////////////////////////////////////////////////////////////////////////
  // Intern
  //////////////////////////////////////////////////////////////////////////

    public static readonly long NEG = -257;
    public static readonly long POS = 4000;
    public static readonly Long[] m_neg = new Long[-(int)NEG];
    public static readonly Long[] m_pos = new Long[(int)POS];
    public static readonly Long m_maxValue = Long.valueOf(Int64.MaxValue);
    public static readonly Long m_minValue = Long.valueOf(Int64.MinValue);
    public static readonly Long Zero;    // 0
    public static readonly Long One;     // 1
    public static readonly Long NegOne;  // -1
    public static readonly Long NegTwo;  // -2
    public static readonly Long Ten;     // 10
    public static readonly Long LT;      // compare() -> -1
    public static readonly Long EQ;      // compare() ->  0
    public static readonly Long GT;      // compare() ->  1
    public static readonly Long Chunk;   // 4kb / 4096

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

      // Intern
      for (int i=1; i<m_neg.Length; i++) m_neg[i] = Long.valueOf(-i);
      for (int i=0; i<m_pos.Length; i++) m_pos[i] = Long.valueOf(i);
      Zero   = Long.valueOf(0);
      One    = Long.valueOf(1);
      NegOne = Long.valueOf(-1);
      NegTwo = Long.valueOf(-2);
      Ten    = Long.valueOf(10);
      LT     = Long.valueOf(-1);
      EQ     = Long.valueOf(0);
      GT     = Long.valueOf(1);
      Chunk  = Long.valueOf(4096);

      // Zeros
      zeros[0] = "";
      for (int i=1; i<zeros.Length; ++i)
        zeros[i] = zeros[i-1] + "0";
    }

  }
}