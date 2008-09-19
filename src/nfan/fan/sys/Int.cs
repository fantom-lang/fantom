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
  /// Int is a 64-bit integer value.
  /// </summary>
  public sealed class Int : Num, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Int fromStr(Str s) { return fromStr(s, Ten, Bool.True); }
    public static Int fromStr(Str s, Int radix) { return fromStr(s, radix, Bool.True); }
    public static Int fromStr(Str s, Int radix, Bool check)
    {
      try
      {
        return make(Convert.ToInt64(s.val, (int)radix.val));
      }
      catch (FormatException)
      {
        if (!check.val) return null;
        throw ParseErr.make("Int", s).val;
      }
    }

    public static Int random() { return random(null); }
    public static Int random(Range r)
    {
      rand.GetBytes(randBytes);
      long v = BitConverter.ToInt64(randBytes, 0);
      if (r == null) return make(v);
      if (v < 0) v = -v;
      long start = r.start().val;
      long end   = r.end().val;
      if (r.inclusive().val) ++end;
      return make(start + (v % (end-start)));
    }

    static byte[] randBytes = new byte[8];
    static readonly System.Security.Cryptography.RNGCryptoServiceProvider
      rand = new System.Security.Cryptography.RNGCryptoServiceProvider();

    public static Int make(long val)
    {
      if (val < POS)
      {
        if (val >= 0) return m_pos[(int)val];
        if (val > NEG) return m_neg[-(int)val];
      }
      return new Int(val);
    }

    public static Int pos(long val)
    {
      if (val < POS)
      {
        return m_pos[(int)val];
      }
      return new Int(val);
    }

    private Int(long val) { this.val = val; }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool equals(Obj obj)
    {
      if (obj is Int)
        return val == ((Int)obj).val ? Bool.True : Bool.False;
      else
        return Bool.False;
    }

    public override Int compare(Obj obj)
    {
      long that = ((Int)obj).val;
      if (val < that) return LT; return val == that ? EQ : GT;
    }

    public override int GetHashCode()
    {
      return (int)(val ^ (int)(((ulong)val) >> 32));
    }

    public override Int hash()
    {
      return this;
    }

    public override Type type()
    {
      return Sys.IntType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Int negate()  { return make(-val); }
    public Int inverse() { return make(~val); }
    public Int mult      (Int x) { return make(val * x.val); }
    public Int div       (Int x) { return make(val / x.val); }
    public Int mod       (Int x) { return make(val % x.val); }
    public Int plus      (Int x) { return make(val + x.val); }
    public Int minus     (Int x) { return make(val - x.val); }
    public Int and       (Int x) { return make(val & x.val); }
    public Int or        (Int x) { return make(val | x.val); }
    public Int xor       (Int x) { return make(val ^ x.val); }
    public Int lshift    (Int x) { return make(val << (int)x.val); }
    public Int rshift    (Int x) { return make(val >> (int)x.val); }
    public Int increment ()      { return make(val+1); }
    public Int decrement ()      { return make(val-1); }

  //////////////////////////////////////////////////////////////////////////
  // Num
  //////////////////////////////////////////////////////////////////////////

    public override Int toInt() { return this; }

    public override Float toFloat() { return Float.make(val); }

    public override Decimal toDecimal() { return Decimal.make(new decimal(val)); }

  //////////////////////////////////////////////////////////////////////////
  // Math
  //////////////////////////////////////////////////////////////////////////

    public Int abs()
    {
      if (val >= 0) return this;
      return Int.pos(-val);
    }

    public Int min(Int that)
    {
      if (val <= that.val) return this;
      return that;
    }

    public Int max(Int that)
    {
      if (val >= that.val) return this;
      return that;
    }

    public Bool isEven()
    {
      return (val % 2) == 0 ? Bool.True : Bool.False;
    }

    public Bool isOdd()
    {
      return (val % 2) != 0 ? Bool.True : Bool.False;
    }

  /////////////////////////////////////////////////////////////////////////
  // Char
  //////////////////////////////////////////////////////////////////////////

    public Bool isSpace()
    {
      try
      {
        if (val < 128 && (charMap[(int)val] & SPACE) != 0)
          return Bool.True;
        else
          return Bool.False;
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return Bool.False;
      }
    }

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

    public Bool isAlpha()
    {
      try
      {
        if (val < 128 && (charMap[(int)val] & (UPPER|LOWER)) != 0)
          return Bool.True;
        else
          return Bool.False;
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return Bool.False;
      }
    }

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

    public Bool isAlphaNum()
    {
      try
      {
        if (val < 128 && (charMap[(int)val] & (UPPER|LOWER|DIGIT)) != 0)
          return Bool.True;
        else
          return Bool.False;
      }
      catch (IndexOutOfRangeException)
      {
        // should be very rare to use this method with negative
        // numbers, so don't take the hit every call
        return Bool.False;
      }
    }

    public Bool isUpper()
    {
      return 'A' <= val && val <= 'Z' ? Bool.True : Bool.False;
    }

    public Bool isLower()
    {
      return 'a' <= val && val <= 'z' ? Bool.True : Bool.False;
    }

    public Int upper()
    {
      if ('a' <= val && val <= 'z')
        return m_pos[((int)val) & ~0x20];
      else
        return this;
    }

    public Int lower()
    {
      if ('A' <= val && val <= 'Z')
        return m_pos[((int)val) | 0x20];
      else
        return this;
    }

    public Bool isDigit()
    {
      return '0' <= val && val <= '9' ? Bool.True : Bool.False;
    }

    public Bool isDigit(Int radix)
    {
      if (val < 0 || val >= 128) return Bool.False;
      int v = (int)val;
      int r = (int)radix.val;

      if (r == 10)
      {
        return ((charMap[v] & DIGIT) != 0) ? Bool.True : Bool.False;
      }

      if (r == 16)
      {
        return ((charMap[v] & HEX) != 0) ? Bool.True : Bool.False;
      }

      if (r <= 10)
      {
        return '0' <= v && v <= ('0'+r) ?  Bool.True : Bool.False;
      }
      else
      {
        if ((charMap[v] & DIGIT) != 0) return Bool.True;
        int x = v-10;
        if ('a' <= v && v <= 'a'+x) return Bool.True;
        if ('A' <= v && v <= 'A'+x) return Bool.True;
        return Bool.False;
      }
    }

    public Int toDigit()
    {
      if (0 <= val && val <= 9) return m_pos[(int)val + '0'];
      return null;
    }

    public Int toDigit(Int radix)
    {
      int val = (int)this.val;
      int r   = (int)radix.val;
      if (val < 0 || val >= r) return null;

      if (val < 10) return m_pos[val + '0'];
      return m_pos[val - 10 + 'a'];
    }

    public Int fromDigit()
    {
      if ('0' <= val && val <= '9') return m_pos[(int)val - '0'];
      return null;
    }

    public Int fromDigit(Int radix)
    {
      if (val < 0 || val >= 128) return null;
      int v = (int)val;
      int r = (int)radix.val;

      int ten = r < 10 ? r : 10;
      if ('0' <= v && v < '0'+ten) return m_pos[v - '0'];
      if (r > 10)
      {
        int alpha = r-10;
        if ('a' <= v && v < 'a'+alpha) return m_pos[v + 10 - 'a'];
        if ('A' <= v && v < 'A'+alpha) return m_pos[v + 10 - 'A'];
      }
      return null;
    }

    public Bool equalsIgnoreCase(Int ch)
    {
      return (val | 0x20L) == (ch.val | 0x20L) ? Bool.True : Bool.False;
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

    public Bool localeIsUpper()
    {
      return Char.IsUpper((char)val) ? Bool.True : Bool.False;
    }

    public Bool localeIsLower()
    {
      return Char.IsLower((char)val) ? Bool.True : Bool.False;
    }

    public Int localeUpper()
    {
      return pos(Char.ToUpper((char)val, Locale.current().net()));
    }

    public Int localeLower()
    {
      return pos(Char.ToLower((char)val, Locale.current().net()));
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public Str toChar()
    {
      if (val < 0 || val > 0xFFFF) throw Err.make("Invalid unicode char: " + val).val;
      if (val < Str.m_ascii.Length) return Str.m_ascii[(int)val];
      return Str.make("" + (char)val);
    }

    public Str toHex() { return toHex(null); }
    public Str toHex(Int width)
    {
      string s = val.ToString("X").ToLower();
      if (width != null && s.Length < width.val)
        s = zeros[(int)width.val-s.Length] + s;
      return Str.make(s);
    }
    static string[] zeros = new string[16];

    public override Str toStr()
    {
      if (m_str == null) m_str = Str.make("" + val);
      return m_str;
    }

    public void encode(ObjEncoder @out)
    {
      @out.w(val.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Closures
  //////////////////////////////////////////////////////////////////////////

    public void times(Func f)
    {
      for (long i=0; i<val; i++)
        f.call1(Int.make(i));
    }

  //////////////////////////////////////////////////////////////////////////
  // Intern
  //////////////////////////////////////////////////////////////////////////

    public static readonly long NEG = -257;
    public static readonly long POS = 4000;
    public static readonly Int[] m_neg = new Int[-(int)NEG];
    public static readonly Int[] m_pos = new Int[(int)POS];
    public static readonly Int m_maxValue = new Int(Int64.MaxValue);
    public static readonly Int m_minValue = new Int(Int64.MinValue);
    public static readonly Int Zero;    // 0
    public static readonly Int One;     // 1
    public static readonly Int NegOne;  // -1
    public static readonly Int NegTwo;  // -2
    public static readonly Int Ten;     // 10
    public static readonly Int LT;      // compare() -> -1
    public static readonly Int EQ;      // compare() ->  0
    public static readonly Int GT;      // compare() ->  1
    public static readonly Int Chunk;   // 4kb / 4096

    static Int()
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
      for (int i=1; i<m_neg.Length; i++) m_neg[i] = new Int(-i);
      for (int i=0; i<m_pos.Length; i++) m_pos[i] = new Int(i);
      Zero   = make(0);
      One    = make(1);
      NegOne = make(-1);
      NegTwo = make(-2);
      Ten    = make(10);
      LT     = make(-1);
      EQ     = make(0);
      GT     = make(1);
      Chunk  = make(4096);

      // Zeros
      zeros[0] = "";
      for (int i=1; i<zeros.Length; ++i)
        zeros[i] = zeros[i-1] + "0";
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly long val;
    private Str m_str;
  }
}
