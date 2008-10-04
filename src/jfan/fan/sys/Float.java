//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * Float is a 64-bit floating point value.
 */
public final class Float
  extends Num
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Float fromStr(Str s) { return fromStr(s, Bool.True); }
  public static Float fromStr(Str s, Bool checked)
  {
    try
    {
      String x = s.val;
      if (x.equals("NaN"))  return nan;
      if (x.equals("INF"))  return posInf;
      if (x.equals("-INF")) return negInf;
      return make(Double.parseDouble(x));
    }
    catch (NumberFormatException e)
    {
      if (!checked.val) return null;
      throw ParseErr.make("Float",  s).val;
    }
  }

  public static Float make(double val)
  {
    if (val == 0) return Zero;
    return new Float(val);
  }

  public static Float makeBits(Int bits)
  {
    return make(Double.longBitsToDouble(bits.val));
  }

  public static Float makeBits32(Int bits)
  {
    return make(java.lang.Float.intBitsToFloat((int)bits.val));
  }

  private Float(double val) { this.val = val; }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Bool _equals(Obj obj)
  {
    if (obj instanceof Float)
    {
      double x = ((Float)obj).val;
      if (Double.isNaN(val)) return Bool.make(Double.isNaN(x));
      return val == x ? Bool.True : Bool.False;
    }
    return Bool.False;
  }

  public Bool approx(Float that) { return approx(that, null); }
  public Bool approx(Float that, Float tolerance)
  {
    // need this to check +inf, -inf, and nan
    if (equals(that)) return Bool.True;

    double t;
    if (tolerance == null)
      t = Math.min( Math.abs(val/1e6), Math.abs(that.val/1e6) );
    else
      t = tolerance.val;
    return Math.abs(val - that.val) <= t ? Bool.True : Bool.False;
  }

  public Int compare(Obj obj)
  {
    double that = ((Float)obj).val;
    if (Double.isNaN(val))
    {
      return (Double.isNaN(that)) ? Int.EQ : Int.LT;
    }
    else if (Double.isNaN(that))
    {
      return Int.GT;
    }
    else
    {
      if (val < that) return Int.LT; return val == that ? Int.EQ : Int.GT;
    }
  }

  public int hashCode()
  {
    long hash = Double.doubleToLongBits(val);
    return (int)(hash ^ (hash >>> 32));
  }

  public Int hash()
  {
    return bits();
  }

  public Int bits()
  {
    return Int.make(Double.doubleToLongBits(val));
  }

  public Int bits32()
  {
    return Int.make(java.lang.Float.floatToIntBits((float)val) & 0xFFFFFFFFL);
  }

  public Type type()
  {
    return Sys.FloatType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public Float negate() { return make(-val); }
  public Float mult      (Float x) { return make(val * x.val); }
  public Float div       (Float x) { return make(val / x.val); }
  public Float mod       (Float x) { return make(val % x.val); }
  public Float plus      (Float x) { return make(val + x.val); }
  public Float minus     (Float x) { return make(val - x.val); }
  public Float increment ()        { return make(val+1); }
  public Float decrement ()        { return make(val-1); }

//////////////////////////////////////////////////////////////////////////
// Num
//////////////////////////////////////////////////////////////////////////

  public Int toInt() { return Int.make((long)val); }

  public Float toFloat() { return this; }

  public Decimal toDecimal() { return Decimal.make(new java.math.BigDecimal(val)); }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public Float abs()
  {
    if (val >= 0) return this;
    return make(-val);
  }

  public Float min(Float that)
  {
    if (val <= that.val) return this;
    return that;
  }

  public Float max(Float that)
  {
    if (val >= that.val) return this;
    return that;
  }

  public Float ceil()
  {
    return make(Math.ceil(val));
  }

  public Float floor()
  {
    return make(Math.floor(val));
  }

  public Float round()
  {
    return make(Math.rint(val));
  }

  public Float exp()
  {
    return make(Math.exp(val));
  }

  public Float log()
  {
    return make(Math.log(val));
  }

  public Float log10()
  {
    return make(Math.log10(val));
  }

  public Float pow(Float pow)
  {
    return make(Math.pow(val, pow.val));
  }

  public Float sqrt()
  {
    return make(Math.sqrt(val));
  }

//////////////////////////////////////////////////////////////////////////
// Trig
//////////////////////////////////////////////////////////////////////////

  public Float acos()
  {
    return make(Math.acos(val));
  }

  public Float asin()
  {
    return make(Math.asin(val));
  }

  public Float atan()
  {
    return make(Math.atan(val));
  }

  public static Float atan2(Float y, Float x)
  {
    return make(Math.atan2(y.val, x.val));
  }

  public Float cos()
  {
    return make(Math.cos(val));
  }

  public Float cosh()
  {
    return make(Math.cosh(val));
  }

  public Float sin()
  {
    return make(Math.sin(val));
  }

  public Float sinh()
  {
    return make(Math.sinh(val));
  }

  public Float tan()
  {
    return make(Math.tan(val));
  }

  public Float tanh()
  {
    return make(Math.tanh(val));
  }

  public Float toDegrees()
  {
    return make(Math.toDegrees(val));
  }

  public Float toRadians()
  {
    return make(Math.toRadians(val));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public Str toStr()
  {
    if (Double.isNaN(val)) return NaNStr;
    if (val == Double.POSITIVE_INFINITY) return PosInfStr;
    if (val == Double.NEGATIVE_INFINITY) return NegInfStr;
    return Str.make(Double.toString(val));
  }

  public void encode(ObjEncoder out)
  {
    if (Double.isNaN(val)) out.w("sys::Float(\"NaN\")");
    else if (val == Double.POSITIVE_INFINITY) out.w("sys::Float(\"INF\")");
    else if (val == Double.NEGATIVE_INFINITY) out.w("sys::Float(\"-INF\")");
    else out.w(Double.toString(val)).w("f");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Float Zero   = new Float(0);
  public static final Float posInf = new Float(Double.POSITIVE_INFINITY);
  public static final Float negInf = new Float(Double.NEGATIVE_INFINITY);
  public static final Float nan    = new Float(Double.NaN);
  public static final Float e      = new Float(Math.E);
  public static final Float pi     = new Float(Math.PI);
  public static final Str PosInfStr = Str.make("INF");
  public static final Str NegInfStr = Str.make("-INF");
  public static final Str NaNStr    = Str.make("NaN");

  public final double val;

}