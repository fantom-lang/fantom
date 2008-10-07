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
  ///
  /// Float is a 64-bit floating point value.
  ///
  public sealed class Float : Num, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Float fromStr(Str s) { return fromStr(s, Bool.True); }
    public static Float fromStr(Str s, Bool check)
    {
      try
      {
        string x = s.val;
        if (x == "NaN")  return m_nan;
        if (x == "INF") return m_posInf;
        if (x == "-INF") return m_negInf;
        return make(Double.Parse(x));
      }
      catch (FormatException)
      {
        if (!check.val) return null;
        throw ParseErr.make("Float", s).val;
      }
    }

    public static Float make(double val)
    {
      if (val == 0) return m_zero;
      return new Float(val);
    }

    public static Float makeBits(Int bits)
    {
      return make(BitConverter.Int64BitsToDouble(bits.val));
    }

    public static Float makeBits32(Int bits)
    {
      return make(BitConverter.ToSingle(BitConverter.GetBytes(bits.val), 0));
    }

    private Float(double val) { this.val = val; }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool _equals(Obj obj)
    {
      if (obj is Float)
      {
        double x = ((Float)obj).val;
        if (Double.IsNaN(val)) return Bool.make(Double.IsNaN(x));
        return val == x ? Bool.True : Bool.False;
      }
      return Bool.False;
    }

    public Bool approx(Float that) { return approx(that, null); }
    public Bool approx(Float that, Float tolerance)
    {
      // need this to check +inf, -inf, and nan
      if (Equals(that)) return Bool.True;

      double t;
      if (tolerance == null)
        t = Math.Min( Math.Abs(val/1e6), Math.Abs(that.val/1e6) );
      else
        t = tolerance.val;
      return Math.Abs(val - that.val) <= t ? Bool.True : Bool.False;
    }

    public override Int compare(Obj obj)
    {
      double that = ((Float)obj).val;
      if (Double.IsNaN(val))
      {
        return (Double.IsNaN(that)) ? Int.EQ : Int.LT;
      }
      else if (Double.IsNaN(that))
      {
        return Int.GT;
      }
      else
      {
        if (val < that) return Int.LT; return val == that ? Int.EQ : Int.GT;
      }
    }

    public override int GetHashCode()
    {
      long hash = BitConverter.DoubleToInt64Bits(val);
      return (int)(hash ^ (hash >> 32));
    }

    public override Int hash()
    {
      return bits();
    }

    public Int bits()
    {
      return Int.make(BitConverter.DoubleToInt64Bits(val));
    }

    public Int bits32()
    {
      return Int.make(BitConverter.ToInt32(BitConverter.GetBytes((float)val), 0) & 0xFFFFFFFFL);
    }

    public override Type type()
    {
      return Sys.FloatType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Float negate    ()        { return make(-val); }
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

    public override Int toInt()
    {
      // TODO
      if (val == Double.PositiveInfinity) return Int.make(Int64.MaxValue);
      if (Double.IsNaN(val)) return Int.Zero;
      return Int.make((long)val);
    }

    public override Float toFloat() { return this; }

    public override Decimal toDecimal() { return Decimal.make(new decimal(val)); }

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
      return make(Math.Ceiling(val));
    }

    public Float floor()
    {
      return make(Math.Floor(val));
    }

    public Float round()
    {
      return make(Math.Round(val));
    }

    public Float exp()
    {
      return make(Math.Exp(val));
    }

    public Float log()
    {
      return make(Math.Log(val));
    }

    public Float log10()
    {
      return make(Math.Log10(val));
    }

    public Float pow(Float pow)
    {
      return make(Math.Pow(val, pow.val));
    }

    public Float sqrt()
    {
      return make(Math.Sqrt(val));
    }

  //////////////////////////////////////////////////////////////////////////
  // Trig
  //////////////////////////////////////////////////////////////////////////

    public Float acos()
    {
      return make(Math.Acos(val));
    }

    public Float asin()
    {
      return make(Math.Asin(val));
    }

    public Float atan()
    {
      return make(Math.Atan(val));
    }

    public static Float atan2(Float y, Float x)
    {
      return make(Math.Atan2(y.val, x.val));
    }

    public Float cos()
    {
      return make(Math.Cos(val));
    }

    public Float cosh()
    {
      return make(Math.Cosh(val));
    }

    public Float sin()
    {
      return make(Math.Sin(val));
    }

    public Float sinh()
    {
      return make(Math.Sinh(val));
    }

    public Float tan()
    {
      return make(Math.Tan(val));
    }

    public Float tanh()
    {
      return make(Math.Tanh(val));
    }

    public Float toDegrees()
    {
      return make((180 / Math.PI) * val);
    }

    public Float toRadians()
    {
      return make((val * Math.PI) / 180);
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr()
    {
      if (Double.IsNaN(val)) return m_NaNStr;
      if (val == Double.PositiveInfinity) return m_PosInfStr;
      if (val == Double.NegativeInfinity) return m_NegInfStr;
      string s = val.ToString();
      if (s.IndexOf('.') == -1) s += ".0";  // to match java behavior
      return Str.make(s);
    }

    public void encode(ObjEncoder @out)
    {
      if (Double.IsNaN(val)) @out.w("sys::Float(\"NaN\")");
      else if (val == Double.PositiveInfinity) @out.w("sys::Float(\"INF\")");
      else if (val == Double.NegativeInfinity) @out.w("sys::Float(\"-INF\")");
      else
      {
        string s = val.ToString();
        @out.w(s).w("f");
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Float m_zero   = new Float(0);
    public static readonly Float m_posInf = new Float(Double.PositiveInfinity);
    public static readonly Float m_negInf = new Float(Double.NegativeInfinity);
    public static readonly Float m_nan    = new Float(Double.NaN);
    public static readonly Float m_e      = new Float(Math.E);
    public static readonly Float m_pi     = new Float(Math.PI);
    public static readonly Str m_PosInfStr = Str.make("INF");
    public static readonly Str m_NegInfStr = Str.make("-INF");
    public static readonly Str m_NaNStr    = Str.make("NaN");

    public readonly double val;
  }
}