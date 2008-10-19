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
 * FanFloat defines the methods for sys::Float:
 *   sys::Float   =>  double primitive
 *   sys::Float?  =>  java.lang.Double
 */
public final class FanFloat
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Double fromStr(String s) { return fromStr(s, true); }
  public static Double fromStr(String s, boolean checked)
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

  public static double makeBits(long bits)
  {
    return Double.longBitsToDouble(bits);
  }

  public static double makeBits32(long bits)
  {
    return Float.intBitsToFloat((int)bits);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static boolean equals(double self, Object obj)
  {
    if (obj instanceof Double)
    {
      double x = ((Double)obj).doubleValue();
      if (Double.isNaN(self)) return Double.isNaN(x);
      return self == x;
    }
    return false;
  }

  public static boolean approx(double self, double that) { return approx(self, that, null); }
  public static boolean approx(double self, double that, Double tolerance)
  {
    // need this to check +inf, -inf, and nan
    if (equals(self, that)) return true;

    double t;
    if (tolerance == null)
      t = Math.min( Math.abs(self/1e6), Math.abs(that/1e6) );
    else
      t = tolerance.doubleValue();
    return Math.abs(self - that) <= t;
  }

  public static long compare(double self, Object obj)
  {
    double that = ((Double)obj).doubleValue();
    if (Double.isNaN(self))
    {
      return (Double.isNaN(that)) ? FanInt.EQ : FanInt.LT;
    }
    else if (Double.isNaN(that))
    {
      return FanInt.GT;
    }
    else
    {
      if (self < that) return FanInt.LT; return self == that ? FanInt.EQ : FanInt.GT;
    }
  }

  public static long hash(double self)
  {
    return bits(self);
  }

  public static long bits(double self)
  {
    return Double.doubleToLongBits(self);
  }

  public static long bits32(double self)
  {
    return Float.floatToIntBits((float)self) & 0xFFFFFFFFL;
  }

  public static Type type(double self)
  {
    return Sys.FloatType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public static double negate(double self)
  {
    return -self;
  }

  public static double mult(double self, double x)
  {
    return self * x;
  }

  public static double div(double self, double x)
  {
    return self / x;
  }

  public static double mod(double self, double x)
  {
    return self % x;
  }

  public static double plus(double self, double x)
  {
    return self + x;
  }

  public static double minus(double self, double x)
  {
    return self - x;
  }

  public static double increment(double self)
  {
    return self + 1.0;
  }

  public static double decrement(double self)
  {
    return self - 1.0;
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public static double abs(double self)
  {
    if (self >= 0) return self;
    return -self;
  }

  public static double min(double self, double that)
  {
    if (self <= that) return self;
    return that;
  }

  public static double max(double self, double that)
  {
    if (self >= that) return self;
    return that;
  }

  public static double ceil(double self)
  {
    return Math.ceil(self);
  }

  public static double floor(double self)
  {
    return Math.floor(self);
  }

  public static double round(double self)
  {
    return Math.rint(self);
  }

  public static double exp(double self)
  {
    return Math.exp(self);
  }

  public static double log(double self)
  {
    return Math.log(self);
  }

  public static double log10(double self)
  {
    return Math.log10(self);
  }

  public static double pow(double self, double pow)
  {
    return Math.pow(self, pow);
  }

  public static double sqrt(double self)
  {
    return Math.sqrt(self);
  }

//////////////////////////////////////////////////////////////////////////
// Trig
//////////////////////////////////////////////////////////////////////////

  public static double acos(double self)
  {
    return Math.acos(self);
  }

  public static double asin(double self)
  {
    return Math.asin(self);
  }

  public static double atan(double self)
  {
    return Math.atan(self);
  }

  public static double atan2(double y, double x)
  {
    return Math.atan2(y, x);
  }

  public static double cos(double self)
  {
    return Math.cos(self);
  }

  public static double cosh(double self)
  {
    return Math.cosh(self);
  }

  public static double sin(double self)
  {
    return Math.sin(self);
  }

  public static double sinh(double self)
  {
    return Math.sinh(self);
  }

  public static double tan(double self)
  {
    return Math.tan(self);
  }

  public static double tanh(double self)
  {
    return Math.tanh(self);
  }

  public static double toDegrees(double self)
  {
    return Math.toDegrees(self);
  }

  public static double toRadians(double self)
  {
    return Math.toRadians(self);
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toStr(double self)
  {
    if (Double.isNaN(self)) return NaNStr;
    if (self == Double.POSITIVE_INFINITY) return PosInfStr;
    if (self == Double.NEGATIVE_INFINITY) return NegInfStr;
    return Double.toString(self);
  }

  public static void encode(double self, ObjEncoder out)
  {
    if (Double.isNaN(self)) out.w("sys::Float(\"NaN\")");
    else if (self == Double.POSITIVE_INFINITY) out.w("sys::Float(\"INF\")");
    else if (self == Double.NEGATIVE_INFINITY) out.w("sys::Float(\"-INF\")");
    else out.w(Double.toString(self)).w("f");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final double posInf = Double.POSITIVE_INFINITY;
  public static final double negInf = Double.NEGATIVE_INFINITY;
  public static final double nan    = Double.NaN;
  public static final double e      = Math.E;
  public static final double pi     = Math.PI;
  public static final String PosInfStr = "INF";
  public static final String NegInfStr = "-INF";
  public static final String NaNStr    = "NaN";

}