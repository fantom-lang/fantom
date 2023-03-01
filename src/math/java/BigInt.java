//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//

package fan.math;

import java.math.BigDecimal;
import java.math.BigInteger;
import fan.sys.*;

public final class BigInt extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static BigInt fromStr(final String s) { return fromStr(s, 10); }
  public static BigInt fromStr(final String s, final long radix) { return fromStr(s, radix, true); }
  public static BigInt fromStr(final String s, final long radix, final boolean checked)
  {
    try
    {
      return new BigInt(new BigInteger(s, (int)radix));
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("BigInt", s);
    }
  }

  public static BigInt makeInt(final long val)
  {
    return new BigInt(BigInteger.valueOf(val));
  }

  public static BigInt makeBuf(Buf bytes)
  {
    return new BigInt(new BigInteger(bytes.safeArray()));
  }

  public BigInt(BigInteger val)
  {
    this.self = val;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Type typeof() { return typeof; }
  private static final Type typeof = Type.find("math::BigInt");

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public BigInt negate() { return new BigInt(self.negate()); }

  public BigInt increment() { return new BigInt(self.add(BigInteger.ONE)); }

  public BigInt decrement() { return new BigInt(self.subtract(BigInteger.ONE)); }

  public BigInt mult(BigInt x) { return new BigInt(self.multiply(x.self)); }
  public BigInt multInt(long x) { return new BigInt(self.multiply(BigInteger.valueOf(x))); }

  public BigInt div(BigInt x) { return new BigInt(self.divide(x.self)); }
  public BigInt divInt(long x) { return new BigInt(self.divide(BigInteger.valueOf(x))); }

  public BigInt mod(BigInt x) { return new BigInt(self.remainder(x.self)); }
  public long modInt(long x) { return self.remainder(BigInteger.valueOf(x)).longValue(); }

  public BigInt plus(BigInt x) { return new BigInt(self.add(x.self)); }
  public BigInt plusInt(long x) { return new BigInt(self.add(BigInteger.valueOf(x))); }

  public BigInt minus(BigInt x) { return new BigInt(self.subtract(x.self)); }
  public BigInt minusInt(long x) { return new BigInt(self.subtract(BigInteger.valueOf(x))); }

//////////////////////////////////////////////////////////////////////////
// Bitwise
//////////////////////////////////////////////////////////////////////////

  public BigInt setBit(final long bit) { return new BigInt(self.setBit((int)bit)); }

  public BigInt clearBit(final long bit) { return new BigInt(self.clearBit((int)bit)); }

  public BigInt flipBit(final long bit) { return new BigInt(self.flipBit((int)bit)); }

  public boolean testBit(final long bit) { return self.testBit((int)bit); }

  public long bitLen() { return self.bitLength(); }

  public BigInt not() { return new BigInt(self.not()); }

  public BigInt and(Object b) { return new BigInt(self.and(bi(b))); }

  public BigInt or(Object b) { return new BigInt(self.or(bi(b))); }

  public BigInt xor(Object b) { return new BigInt(self.xor(bi(b))); }

  public BigInt shiftl(long b) { return new BigInt(self.shiftLeft((int)b)); }

  public BigInt shiftr(long b) { return new BigInt(self.shiftRight((int)b)); }

  private static BigInteger bi(Object obj)
  {
    if (obj instanceof BigInt) return ((BigInt)obj).self;
    if (obj instanceof Long) return BigInteger.valueOf((Long)obj);
    throw ArgErr.make("Not a BigInt or Int: " + obj.getClass());
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public long signum() { return self.signum(); }

  public BigInt abs() { return new BigInt(self.abs()); }

  public BigInt min(BigInt x) { return new BigInt(self.min(x.self)); }

  public BigInt max(BigInt x) { return new BigInt(self.max(x.self)); }

  public BigInt pow(long x)
  {
    int asInt = x > (long)Integer.MAX_VALUE
      ? Integer.MAX_VALUE
      : (x < (long)Integer.MIN_VALUE
        ? Integer.MIN_VALUE
        : (int)x);
    return new BigInt(self.pow(asInt));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public long toInt() { return toInt(true); }
  public long toInt(final boolean checked)
  {
    // longValueExact() is 1.8 only, but preferable
    return checked ? self.longValueExact() : self.longValue();
  }

  public double toFloat() { return self.floatValue(); }

  public BigDecimal toDecimal() { return new BigDecimal(self); }

  public Buf toBuf()
  {
    return new MemBuf(self.toByteArray());
  }

  public String toRadix(long radix) { return toRadix(radix, null); }
  public String toRadix(long radix, Long width)
  {
    return pad(self.toString((int)radix), width);
  }

  // Taken from FanInt.java
  private static String pad(String s, Long width)
  {
    if (width == null || s.length() >= width.intValue()) return s;
    StringBuilder sb = new StringBuilder(width.intValue());
    int zeros = width.intValue() - s.length();
    for (int i=0; i<zeros; ++i) sb.append('0');
    sb.append(s);
    return sb.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public boolean equals(Object obj)
  {
    if (obj instanceof BigInt)
    {
      BigInt that = (BigInt)obj;
      return self.equals(that.self);
    }
    return false;
  }

  public long compare(Object obj)
  {
    BigInt that = (BigInt)obj;
    return self.compareTo(that.self);
  }

  public long hash()
  {
    return self.hashCode();
  }

  public String toStr()
  {
    return self.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final BigInt defVal = new BigInt(BigInteger.ZERO);
  public static final BigInt zero   = defVal;
  public static final BigInt one    = new BigInt(BigInteger.ONE);

  private BigInteger self;

}