//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//

package fan.math;

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
// Identity
//////////////////////////////////////////////////////////////////////////

 	public static final BigInt defVal = new BigInt(BigInteger.ZERO);
 	public static final BigInt zero   = defVal;
 	public static final BigInt one    = new BigInt(BigInteger.ONE);

	public long signum() { return self.signum(); }

	public long toInt() { return toInt(true); }
	public long toInt(final boolean checked)
	{
		// longValueExact() is 1.8 only, but preferable
		return self.longValue();
//		return checked ? self.longValueExact() : self.longValue();
	}

	public Buf toBuf()
	{
		return new MemBuf(self.toByteArray());
	}

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public BigInt negate() { return new BigInt(self.negate()); }

  public BigInt increment() { return new BigInt(self.add(BigInteger.ONE)); }

 	public BigInt decrement() { return new BigInt(self.subtract(BigInteger.ONE)); }

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

  public BigInt abs()
  {
  	return new BigInt(self.abs());
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

  private BigInteger self;

}