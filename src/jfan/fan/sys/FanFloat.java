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
      return (Double.isNaN(that)) ? 0 : -1;
    }
    else if (Double.isNaN(that))
    {
      return +1;
    }
    else
    {
      if (self < that) return -1; return self == that ? 0 : +1;
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

  public static String toCode(double self)
  {
    if (Double.isNaN(self)) return "Float.nan";
    if (self == Double.POSITIVE_INFINITY) return "Float.posInf";
    if (self == Double.NEGATIVE_INFINITY) return "Float.negInf";
    return Double.toString(self) + "f";
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toLocale(double self) { return toLocale(self, null); }
  public static String toLocale(double self, String pattern)
  {
    // get current locale
    Locale locale = Locale.current();
    java.text.DecimalFormatSymbols df = locale.decimal();

    // handle special values
    if (Double.isNaN(self)) return df.getNaN();
    if (self == Double.POSITIVE_INFINITY) return df.getInfinity();
    if (self == Double.NEGATIVE_INFINITY) return df.getMinusSign() + df.getInfinity();

    // get default pattern if necessary
    if (pattern == null) pattern = locale.get("sys", "float", "#,###.0##");

    // parse pattern and get double digits
    NumPattern p = NumPattern.parse(pattern);
    NumDigits d = new NumDigits(self);

    // string buffer
    StringBuilder s = new StringBuilder();
    if (d.negative) s.append(df.getMinusSign());

    // if we have more frac digits then maxFrac, then round off
    d.round(p.maxFrac);

    // if we have an optional integer part, and only
    // fractional digits, then don't include leading zero
    int start = 0;
    if (p.optInt && d.zeroInt())
    {
      start = d.decimal;
      // Java DecimalFormat doesn't do this for negative numbers,
      // which seems a bit inconsistent, but duplicate that behavior
      if (d.negative) s.append('0');
    }

    // if min required fraction digits are zero and we
    // have nothing but zeros, then truncate to a whole number
    if (p.minFrac == 0 && d.zeroFrac(p.maxFrac)) d.size = d.decimal;

    // leading zeros
    for (int i=0; i<p.minInt-d.decimal; ++i) s.append('0');

    // walk thru the digits and apply locale symbols
    for (int i=start; i<d.size; ++i)
    {
      if (i < d.decimal)
      {
        if ((d.decimal - i) % p.group == 0 && i > 0)
          s.append(df.getGroupingSeparator());
      }
      else
      {
        if (i == d.decimal && p.maxFrac > 0) s.append(df.getDecimalSeparator());
        if (i-d.decimal >= p.maxFrac) break;
      }
      s.append(d.digits[i]);
    }

    // trailing zeros
    for (int i=0; i<p.minFrac-d.fracSize(); ++i) s.append('0');

    // handle #.# case
    if (s.length() == 0) return "0";

    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final double posInf = Double.POSITIVE_INFINITY;
  public static final double negInf = Double.NEGATIVE_INFINITY;
  public static final double nan    = Double.NaN;
  public static final double e      = Math.E;
  public static final double pi     = Math.PI;
  public static final double defVal = 0.0;
  public static final String PosInfStr = "INF";
  public static final String NegInfStr = "-INF";
  public static final String NaNStr    = "NaN";

}