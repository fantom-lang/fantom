//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor Float into Double/FanFloat
//
package fan.sys;

import fanx.serial.*;

/**
 * FanDouble defines the methods for sys::Float.  The actual
 * class used for representation is java.lang.Double.
 */
public final class FanFloat
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Double fromStr(String s) { return fromStr(s, true); }
  public static Double fromStr(String s, Boolean checked)
  {
    try
    {
      if (s.equals("NaN"))  return nan;
      if (s.equals("INF"))  return posInf;
      if (s.equals("-INF")) return negInf;
      return Double.valueOf(s);
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("Float", s).val;
    }
  }

  public static Double makeBits(Long bits)
  {
    return Double.valueOf(Double.longBitsToDouble(bits.longValue()));
  }

  public static Double makeBits32(Long bits)
  {
    return Double.valueOf(Float.intBitsToFloat(bits.intValue()));
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static Boolean equals(Double self, Object obj)
  {
    if (obj instanceof Double)
    {
      double val = self.doubleValue();
      double x = ((Double)obj).doubleValue();
      if (Double.isNaN(val)) return Double.isNaN(x);
      return val == x;
    }
    return false;
  }

  public static Boolean approx(Double self, Double that) { return approx(self, that, null); }
  public static Boolean approx(Double self, Double that, Double tolerance)
  {
    // need this to check +inf, -inf, and nan
    if (equals(self, that)) return true;

    double t;
    if (tolerance == null)
      t = Math.min( Math.abs(self.doubleValue()/1e6), Math.abs(that.doubleValue()/1e6) );
    else
      t = tolerance.doubleValue();
    return Math.abs(self.doubleValue() - that.doubleValue()) <= t;
  }

  public static Long compare(Double self, Object obj)
  {
    double val = self.doubleValue();
    double that = ((Double)obj).doubleValue();
    if (Double.isNaN(val))
    {
      return (Double.isNaN(that)) ? FanInt.EQ : FanInt.LT;
    }
    else if (Double.isNaN(that))
    {
      return FanInt.GT;
    }
    else
    {
      if (val < that) return FanInt.LT; return val == that ? FanInt.EQ : FanInt.GT;
    }
  }

  public static Long hash(Double self)
  {
    return bits(self);
  }

  public static Long bits(Double self)
  {
    return Long.valueOf(Double.doubleToLongBits(self.doubleValue()));
  }

  public static Long bits32(Double self)
  {
    return Long.valueOf(Float.floatToIntBits(self.floatValue()) & 0xFFFFFFFFL);
  }

  public static Type type(Double self)
  {
    return Sys.FloatType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public static Double negate(Double self)
  {
    return Double.valueOf(-self.doubleValue());
  }

  public static Double mult(Double self, Double x)
  {
    return Double.valueOf(self.doubleValue() * x.doubleValue());
  }

  public static Double div(Double self, Double x)
  {
    return Double.valueOf(self.doubleValue() / x.doubleValue());
  }

  public static Double mod(Double self, Double x)
  {
    return Double.valueOf(self.doubleValue() % x.doubleValue());
  }

  public static Double plus(Double self, Double x)
  {
    return Double.valueOf(self.doubleValue() + x.doubleValue());
  }

  public static Double minus(Double self, Double x)
  {
    return Double.valueOf(self.doubleValue() - x.doubleValue());
  }

  public static Double increment(Double self)
  {
    return Double.valueOf(self.doubleValue()+1);
  }

  public static Double decrement(Double self)
  {
    return Double.valueOf(self.doubleValue()-1);
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public static Double abs(Double self)
  {
    if (self.doubleValue() >= 0) return self;
    return Double.valueOf(-self.doubleValue());
  }

  public static Double min(Double self, Double that)
  {
    if (self.doubleValue() <= that.doubleValue()) return self;
    return that;
  }

  public static Double max(Double self, Double that)
  {
    if (self.doubleValue() >= that.doubleValue()) return self;
    return that;
  }

  public static Double ceil(Double self)
  {
    return Double.valueOf(Math.ceil(self.doubleValue()));
  }

  public static Double floor(Double self)
  {
    return Double.valueOf(Math.floor(self.doubleValue()));
  }

  public static Double round(Double self)
  {
    return Double.valueOf(Math.rint(self.doubleValue()));
  }

  public static Double exp(Double self)
  {
    return Double.valueOf(Math.exp(self.doubleValue()));
  }

  public static Double log(Double self)
  {
    return Double.valueOf(Math.log(self.doubleValue()));
  }

  public static Double log10(Double self)
  {
    return Double.valueOf(Math.log10(self.doubleValue()));
  }

  public static Double pow(Double self, Double pow)
  {
    return Double.valueOf(Math.pow(self.doubleValue(), pow.doubleValue()));
  }

  public static Double sqrt(Double self)
  {
    return Double.valueOf(Math.sqrt(self.doubleValue()));
  }

//////////////////////////////////////////////////////////////////////////
// Trig
//////////////////////////////////////////////////////////////////////////

  public static Double acos(Double self)
  {
    return Double.valueOf(Math.acos(self.doubleValue()));
  }

  public static Double asin(Double self)
  {
    return Double.valueOf(Math.asin(self.doubleValue()));
  }

  public static Double atan(Double self)
  {
    return Double.valueOf(Math.atan(self.doubleValue()));
  }

  public static Double atan2(Double y, Double x)
  {
    return Double.valueOf(Math.atan2(y.doubleValue(), x.doubleValue()));
  }

  public static Double cos(Double self)
  {
    return Double.valueOf(Math.cos(self.doubleValue()));
  }

  public static Double cosh(Double self)
  {
    return Double.valueOf(Math.cosh(self.doubleValue()));
  }

  public static Double sin(Double self)
  {
    return Double.valueOf(Math.sin(self.doubleValue()));
  }

  public static Double sinh(Double self)
  {
    return Double.valueOf(Math.sinh(self.doubleValue()));
  }

  public static Double tan(Double self)
  {
    return Double.valueOf(Math.tan(self.doubleValue()));
  }

  public static Double tanh(Double self)
  {
    return Double.valueOf(Math.tanh(self.doubleValue()));
  }

  public static Double toDegrees(Double self)
  {
    return Double.valueOf(Math.toDegrees(self.doubleValue()));
  }

  public static Double toRadians(Double self)
  {
    return Double.valueOf(Math.toRadians(self.doubleValue()));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toStr(Double self)
  {
    double val = self.doubleValue();
    if (Double.isNaN(val)) return NaNStr;
    if (val == Double.POSITIVE_INFINITY) return PosInfStr;
    if (val == Double.NEGATIVE_INFINITY) return NegInfStr;
    return Double.toString(val);
  }

  public static void encode(Double self, ObjEncoder out)
  {
    double val = self.doubleValue();
    if (Double.isNaN(val)) out.w("sys::Float(\"NaN\")");
    else if (val == Double.POSITIVE_INFINITY) out.w("sys::Float(\"INF\")");
    else if (val == Double.NEGATIVE_INFINITY) out.w("sys::Float(\"-INF\")");
    else out.w(Double.toString(val)).w("f");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Double Zero   = Double.valueOf(0);
  public static final Double posInf = Double.valueOf(Double.POSITIVE_INFINITY);
  public static final Double negInf = Double.valueOf(Double.NEGATIVE_INFINITY);
  public static final Double nan    = Double.valueOf(Double.NaN);
  public static final Double e      = Double.valueOf(Math.E);
  public static final Double pi     = Double.valueOf(Math.PI);
  public static final String PosInfStr = "INF";
  public static final String NegInfStr = "-INF";
  public static final String NaNStr    = "NaN";

}
