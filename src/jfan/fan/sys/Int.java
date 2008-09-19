//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * Int is a 64-bit integer value.
 */
public final class Int
  extends Num
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Int fromStr(Str s) { return fromStr(s, Ten, Bool.True); }
  public static Int fromStr(Str s, Int radix) { return fromStr(s, radix, Bool.True); }
  public static Int fromStr(Str s, Int radix, Bool checked)
  {
    try
    {
      return make(Long.parseLong(s.val, (int)radix.val));
    }
    catch (NumberFormatException e)
    {
      if (!checked.val) return null;
      throw ParseErr.make("Int",  s).val;
    }
  }

  public static Int random() { return random(null); }
  public static Int random(Range r)
  {
    long v = random.nextLong();
    if (r == null) return make(v);
    if (v < 0) v = -v;
    long start = r.start().val;
    long end   = r.end().val;
    if (r.inclusive().val) ++end;
    return make(start + (v % (end-start)));
  }
  static final java.util.Random random = new java.security.SecureRandom();

  public static Int make(long val)
  {
    if (val < POS)
    {
      if (val >= 0) return pos[(int)val];
      if (val > NEG) return neg[-(int)val];
    }
    return new Int(val);
  }

  public static Int pos(long val)
  {
    if (val < POS)
    {
      return pos[(int)val];
    }
    return new Int(val);
  }

  private Int(long val) { this.val = val; }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Bool equals(Obj obj)
  {
    if (obj instanceof Int)
      return val == ((Int)obj).val ? Bool.True : Bool.False;
    else
      return Bool.False;
  }

  public Int compare(Obj obj)
  {
    long that = ((Int)obj).val;
    if (val < that) return LT; return val == that ? EQ : GT;
  }

  public int hashCode()
  {
    return (int)(val ^ (val >>> 32));
  }

  public Int hash()
  {
    return this;
  }

  public Type type()
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
  public Int lshift    (Int x) { return make(val << x.val); }
  public Int rshift    (Int x) { return make(val >> x.val); }
  public Int increment ()      { return make(val+1); }
  public Int decrement ()      { return make(val-1); }

//////////////////////////////////////////////////////////////////////////
// Num
//////////////////////////////////////////////////////////////////////////

  public Int toInt() { return this; }

  public Float toFloat() { return Float.make(val); }

  public Decimal toDecimal() { return Decimal.make(new java.math.BigDecimal(val)); }

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
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return Bool.False;
    }
  }

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

  public Bool isAlpha()
  {
    try
    {
      if (val < 128 && (charMap[(int)val] & (UPPER|LOWER)) != 0)
        return Bool.True;
      else
        return Bool.False;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return Bool.False;
    }
  }

  public static boolean isAlpha(int val)
  {
    try
    {
      return (val < 128 && (charMap[val] & (UPPER|LOWER)) != 0);
    }
    catch (ArrayIndexOutOfBoundsException e)
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
    catch (ArrayIndexOutOfBoundsException e)
    {
      // should be very rare to use this method with negative
      // numbers, so don't take the hit every call
      return Bool.False;
    }
  }

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
      return pos[((int)val) & ~0x20];
    else
      return this;
  }

  public Int lower()
  {
    if ('A' <= val && val <= 'Z')
      return pos[((int)val) | 0x20];
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
    int val = (int)this.val;
    int r   = (int)radix.val;

    if (r == 10)
    {
      return ((charMap[val] & DIGIT) != 0) ? Bool.True : Bool.False;
    }

    if (r == 16)
    {
      return ((charMap[val] & HEX) != 0) ? Bool.True : Bool.False;
    }

    if (r <= 10)
    {
      return '0' <= val && val <= ('0'+r) ?  Bool.True : Bool.False;
    }
    else
    {
      if ((charMap[val] & DIGIT) != 0) return Bool.True;
      int x = val-10;
      if ('a' <= val && val <= 'a'+x) return Bool.True;
      if ('A' <= val && val <= 'A'+x) return Bool.True;
      return Bool.False;
    }
  }

  public Int toDigit()
  {
    if (0 <= val && val <= 9) return pos[(int)val + '0'];
    return null;
  }

  public Int toDigit(Int radix)
  {
    int val = (int)this.val;
    int r   = (int)radix.val;
    if (val < 0 || val >= r) return null;

    if (val < 10) return pos[val + '0'];
    return pos[val - 10 + 'a'];
  }

  public Int fromDigit()
  {
    if ('0' <= val && val <= '9') return pos[(int)val - '0'];
    return null;
  }

  public Int fromDigit(Int radix)
  {
    if (val < 0 || val >= 128) return null;
    int val = (int)this.val;
    int r   = (int)radix.val;

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

  public Bool equalsIgnoreCase(Int ch)
  {
    return (val | 0x20L) == (ch.val | 0x20L) ? Bool.True : Bool.False;
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

  public Bool localeIsUpper()
  {
    return Character.isUpperCase((int)val) ? Bool.True : Bool.False;
  }

  public Bool localeIsLower()
  {
    return Character.isLowerCase((int)val) ? Bool.True : Bool.False;
  }

  public Int localeUpper()
  {
    // Java doesn't provide a locale Character API
    return pos(Character.toString((char)val).toUpperCase(Locale.current().java()).charAt(0));
  }

  public Int localeLower()
  {
    // Java doesn't provide a locale Character API
    return pos(Character.toString((char)val).toLowerCase(Locale.current().java()).charAt(0));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public Str toChar()
  {
    if (val < 0 || val > 0xFFFF) throw Err.make("Invalid unicode char: " + val).val;
    if (val < Str.ascii.length) return Str.ascii[(int)val];
    return Str.make(String.valueOf((char)val));
  }

  public Str toHex() { return toHex(null); }
  public Str toHex(Int width)
  {
    String s = Long.toHexString(val);
    if (width != null && s.length() < width.val)
      s = zeros[(int)width.val-s.length()] + s;
    return Str.make(s);
  }
  static String[] zeros = new String[16];
  static { zeros[0] = ""; for (int i=1; i<zeros.length; ++i) zeros[i] = zeros[i-1] + "0"; }

  public Str toStr()
  {
    return Str.make(String.valueOf(val));
  }

  public void encode(ObjEncoder out)
  {
    out.w(String.valueOf(val));
  }

//////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  public void times(Func f)
  {
    for (long i=0; i<val; ++i)
      f.call1(Int.make(i));
  }

//////////////////////////////////////////////////////////////////////////
// Intern
//////////////////////////////////////////////////////////////////////////

  public static final long NEG = -257;
  public static final long POS = 4000;
  public static final Int Zero;    // 0
  public static final Int One;     // 1
  public static final Int NegOne;  // -1
  public static final Int NegTwo;  // -2
  public static final Int Ten;     // 10
  public static final Int LT;      // compare() -> -1
  public static final Int EQ;      // compare() ->  0
  public static final Int GT;      // compare() ->  1
  public static final Int Chunk;   // 4kb / 4096
  public static final Int maxValue = new Int(Long.MAX_VALUE);
  public static final Int minValue = new Int(Long.MIN_VALUE);
  static final Int[] neg = new Int[-(int)NEG];
  static final Int[] pos = new Int[(int)POS];

  static
  {
    for (int i=1; i<neg.length; ++i) neg[i] = new Int(-i);
    for (int i=0; i<pos.length; ++i) pos[i] = new Int(i);
    Zero   = make(0);
    One    = make(1);
    NegOne = make(-1);
    NegTwo = make(-2);
    Ten    = make(10);
    LT     = make(-1);
    EQ     = make(0);
    GT     = make(1);
    Chunk  = make(4096);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final long val;

}