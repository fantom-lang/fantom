//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//

using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// FanDouble defines the methods for sys::Float.  The actual
  /// class used for representation is Fan.Sys.Double.
  /// </summary>
  public sealed class FanFloat
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Double fromStr(Str s) { return fromStr(s, Bool.True); }
    public static Double fromStr(Str s, Bool check)
    {
      try
      {
        string x = s.val;
        if (x == "NaN")  return m_nan;
        if (x == "INF")  return m_posInf;
        if (x == "-INF") return m_negInf;
        return Double.valueOf(x);
      }
      catch (System.FormatException)
      {
        if (!check.val) return null;
        throw ParseErr.make("Float", s).val;
      }
    }

    public static Double makeBits(Int bits)
    {
      return Double.valueOf(System.BitConverter.Int64BitsToDouble(bits.val));
    }

    public static Double makeBits32(Int bits)
    {
      return Double.valueOf(System.BitConverter.ToSingle(System.BitConverter.GetBytes(bits.val), 0));
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Bool equals(Double self, object obj)
    {
      if (obj is Double)
      {
        double val = self.doubleValue();
        double x = (obj as Double).doubleValue();
        if (Double.isNaN(val)) return Bool.make(Double.isNaN(x));
        return val == x ? Bool.True : Bool.False;
      }
      return Bool.False;
    }

    public static Bool approx(Double self, Double that) { return approx(self, that, null); }
    public static Bool approx(Double self, Double that, Double tolerance)
    {
      // need this to check +inf, -inf, and nan
      if (equals(self, that).val) return Bool.True;

      double t;
      if (tolerance == null)
        t = System.Math.Min(System.Math.Abs(self.doubleValue()/1e6), System.Math.Abs(that.doubleValue()/1e6));
      else
        t = tolerance.doubleValue();
      return System.Math.Abs(self.doubleValue() - that.doubleValue()) <= t ? Bool.True : Bool.False;
    }

    public static Int compare(Double self, object obj)
    {
      double val = self.doubleValue();
      double that = ((Double)obj).doubleValue();
      if (Double.isNaN(val))
      {
        return (Double.isNaN(that)) ? Int.EQ : Int.LT;
      }
      else if (Double.isNaN(that))
      {
        return Int.LT;
      }
      else
      {
        if (val < that) return Int.LT; return val == that ? Int.EQ : Int.GT;
      }
    }

    public static Int hash(Double self)
    {
      return bits(self);
    }

    public static Int bits(Double self)
    {
      return Int.make(System.BitConverter.DoubleToInt64Bits(self.doubleValue()));
    }

    public static Int bits32(Double self)
    {
      return Int.make(System.BitConverter.ToInt32(System.BitConverter.GetBytes(self.floatValue()), 0) & 0xFFFFFFFFL);
    }

    public static Type type(Double self)
    {
      return Sys.FloatType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static Double negate    (Double self)           { return Double.valueOf(-self.doubleValue()); }
    public static Double mult      (Double self, Double x) { return Double.valueOf(self.doubleValue() * x.doubleValue()); }
    public static Double div       (Double self, Double x) { return Double.valueOf(self.doubleValue() / x.doubleValue()); }
    public static Double mod       (Double self, Double x) { return Double.valueOf(self.doubleValue() % x.doubleValue()); }
    public static Double plus      (Double self, Double x) { return Double.valueOf(self.doubleValue() + x.doubleValue()); }
    public static Double minus     (Double self, Double x) { return Double.valueOf(self.doubleValue() - x.doubleValue()); }
    public static Double increment (Double self)           { return Double.valueOf(self.doubleValue()+1); }
    public static Double decrement (Double self)           { return Double.valueOf(self.doubleValue()-1); }

  //////////////////////////////////////////////////////////////////////////
  // Num
  //////////////////////////////////////////////////////////////////////////

    public static Int toInt(Double self)
    {
      /*
      // TODO
      double val = self.doubleValue();
      if (val == System.Double.PositiveInfinity) return Int.make(System.Int64.MaxValue);
      if (Double.isNaN(val)) return Int.Zero;
      return Int.make(self.longValue());
      */
      return Int.make(self.longValue());
    }

    public static Double toFloat(Double self) { return self; }

    public static Decimal toDecimal(Double self) { return Decimal.make(new decimal(self.doubleValue())); }

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
      return Double.valueOf(System.Math.Ceiling(self.doubleValue()));
    }

    public static Double floor(Double self)
    {
      return Double.valueOf(System.Math.Floor(self.doubleValue()));
    }

    public static Double round(Double self)
    {
      return Double.valueOf(System.Math.Round(self.doubleValue()));
    }

    public static Double exp(Double self)
    {
      return Double.valueOf(System.Math.Exp(self.doubleValue()));
    }

    public static Double log(Double self)
    {
      return Double.valueOf(System.Math.Log(self.doubleValue()));
    }

    public static Double log10(Double self)
    {
      return Double.valueOf(System.Math.Log10(self.doubleValue()));
    }

    public static Double pow(Double self, Double pow)
    {
      return Double.valueOf(System.Math.Pow(self.doubleValue(), pow.doubleValue()));
    }

    public static Double sqrt(Double self)
    {
      return Double.valueOf(System.Math.Sqrt(self.doubleValue()));
    }

  //////////////////////////////////////////////////////////////////////////
  // Trig
  //////////////////////////////////////////////////////////////////////////

    public static Double acos(Double self)
    {
      return Double.valueOf(System.Math.Acos(self.doubleValue()));
    }

    public static Double asin(Double self)
    {
      return Double.valueOf(System.Math.Asin(self.doubleValue()));
    }

    public static Double atan(Double self)
    {
      return Double.valueOf(System.Math.Atan(self.doubleValue()));
    }

    public static Double atan2(Double y, Double x)
    {
      return Double.valueOf(System.Math.Atan2(y.doubleValue(), x.doubleValue()));
    }

    public static Double cos(Double self)
    {
      return Double.valueOf(System.Math.Cos(self.doubleValue()));
    }

    public static Double cosh(Double self)
    {
      return Double.valueOf(System.Math.Cosh(self.doubleValue()));
    }

    public static Double sin(Double self)
    {
      return Double.valueOf(System.Math.Sin(self.doubleValue()));
    }

    public static Double sinh(Double self)
    {
      return Double.valueOf(System.Math.Sinh(self.doubleValue()));
    }

    public static Double tan(Double self)
    {
      return Double.valueOf(System.Math.Tan(self.doubleValue()));
    }

    public static Double tanh(Double self)
    {
      return Double.valueOf(System.Math.Tanh(self.doubleValue()));
    }

    public static Double toDegrees(Double self)
    {
      return Double.valueOf((180 / System.Math.PI) * self.doubleValue());
    }

    public static Double toRadians(Double self)
    {
      return Double.valueOf((self.doubleValue() * System.Math.PI) / 180);
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static Str toStr(Double self)
    {
      double val = self.doubleValue();
      if (Double.isNaN(val)) return m_NaNStr;
      if (val == System.Double.PositiveInfinity) return m_PosInfStr;
      if (val == System.Double.NegativeInfinity) return m_NegInfStr;
      string s = Double.toString(val);
      if (s.IndexOf('.') == -1) s += ".0";  // to match java behavior
      return Str.make(s);
    }

    public static void encode(Double self, ObjEncoder @out)
    {
      double val = self.doubleValue();
      if (Double.isNaN(val)) @out.w("sys::Float(\"NaN\")");
      else if (val == System.Double.PositiveInfinity) @out.w("sys::Float(\"INF\")");
      else if (val == System.Double.NegativeInfinity) @out.w("sys::Float(\"-INF\")");
      else @out.w(Double.toString(val)).w("f");
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Double m_zero   = Double.valueOf(0);
    public static readonly Double m_posInf = Double.valueOf(System.Double.PositiveInfinity);
    public static readonly Double m_negInf = Double.valueOf(System.Double.NegativeInfinity);
    public static readonly Double m_nan    = Double.valueOf(System.Double.NaN);
    public static readonly Double m_e      = Double.valueOf(System.Math.E);
    public static readonly Double m_pi     = Double.valueOf(System.Math.PI);
    public static readonly Str m_PosInfStr = Str.make("INF");
    public static readonly Str m_NegInfStr = Str.make("-INF");
    public static readonly Str m_NaNStr    = Str.make("NaN");

  }
}