//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//   16 Oct 08  Andy Frank  Refactor to FanFloat
//

using System;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// FanDouble defines the methods for sys::Float.  The actual
  /// class used for representation is System.Double.
  /// </summary>
  public sealed class FanFloat
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Double fromStr(string s) { return fromStr(s, true); }
    public static Double fromStr(string s, bool check)
    {
      try
      {
        if (s == "NaN")  return Double.valueOf(m_nan);
        if (s == "INF")  return Double.valueOf(m_posInf);
        if (s == "-INF") return Double.valueOf(m_negInf);
        return Double.valueOf(s);
      }
      catch (FormatException)
      {
        if (!check) return null;
        throw ParseErr.make("Float", s).val;
      }
    }

    public static double makeBits(long bits)
    {
      return BitConverter.Int64BitsToDouble(bits);
    }

    public static double makeBits32(long bits)
    {
      return BitConverter.ToSingle(BitConverter.GetBytes(bits), 0);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static bool equals(double self, object obj)
    {
      if (obj is double)
      {
        double x = (double)obj;
        if (System.Double.IsNaN(self)) return System.Double.IsNaN(x);
        return self == x;
      }
      return false;
    }

    public static bool approx(double self, double that) { return approx(self, that, null); }
    public static bool approx(double self, double that, Double tolerance)
    {
      // need this to check +inf, -inf, and nan
      if (equals(self, that)) return true;

      double t;
      if (tolerance == null)
        t = Math.Min(Math.Abs(self/1e6), Math.Abs(that/1e6));
      else
        t = (tolerance as Double).doubleValue();
      return Math.Abs(self - that) <= t;
    }

    public static long compare(double self, object obj)
    {
      double that = (obj as Double).doubleValue();
      if (System.Double.IsNaN(self))
      {
        return (System.Double.IsNaN(that)) ? 0 : -1;
      }
      else if (System.Double.IsNaN(that))
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
      return BitConverter.DoubleToInt64Bits(self);
    }

    public static long bits32(double self)
    {
      return BitConverter.ToInt32(BitConverter.GetBytes((float)self), 0) & 0xFFFFFFFFL;
    }

    public static Type type(double self)
    {
      return Sys.FloatType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static double negate    (double self)           { return -self; }
    public static double mult      (double self, double x) { return self * x; }
    public static double div       (double self, double x) { return self / x; }
    public static double mod       (double self, double x) { return self % x; }
    public static double plus      (double self, double x) { return self + x; }
    public static double minus     (double self, double x) { return self - x; }
    public static double increment (double self)           { return self+1; }
    public static double decrement (double self)           { return self-1; }

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

    public static double ceil(double self) { return Math.Ceiling(self); }
    public static double floor(double self) { return Math.Floor(self); }
    public static double round(double self) { return Math.Round(self); }
    public static double exp(double self) { return Math.Exp(self); }
    public static double log(double self) { return Math.Log(self); }
    public static double log10(double self) { return Math.Log10(self); }
    public static double pow(double self, double pow) { return Math.Pow(self, pow); }
    public static double sqrt(double self) { return Math.Sqrt(self); }

  //////////////////////////////////////////////////////////////////////////
  // Trig
  //////////////////////////////////////////////////////////////////////////

    public static double acos(double self) { return Math.Acos(self); }
    public static double asin(double self) { return Math.Asin(self); }
    public static double atan(double self) { return Math.Atan(self); }
    public static double atan2(double y, double x) { return Math.Atan2(y, x); }
    public static double cos(double self)  { return Math.Cos(self); }
    public static double cosh(double self) { return Math.Cosh(self); }
    public static double sin(double self)  { return Math.Sin(self); }
    public static double sinh(double self) { return Math.Sinh(self); }
    public static double tan(double self)  { return Math.Tan(self); }
    public static double tanh(double self) { return Math.Tanh(self); }
    public static double toDegrees(double self) { return (180 / Math.PI) * self; }
    public static double toRadians(double self) { return (self * Math.PI) / 180; }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static string toStr(double self)
    {
      if (System.Double.IsNaN(self)) return m_NaNStr;
      if (self == System.Double.PositiveInfinity) return m_PosInfStr;
      if (self == System.Double.NegativeInfinity) return m_NegInfStr;
      string s = self.ToString();
      if (s.IndexOf('.') == -1 && s.IndexOf("E") == -1) s += ".0";  // to match java behavior
      return s;
    }

    public static void encode(double self, ObjEncoder @out)
    {
      if (System.Double.IsNaN(self)) @out.w("sys::Float(\"NaN\")");
      else if (self == System.Double.PositiveInfinity) @out.w("sys::Float(\"INF\")");
      else if (self == System.Double.NegativeInfinity) @out.w("sys::Float(\"-INF\")");
      else @out.w(toStr(self)).w("f");
    }

    public static string toCode(double self)
    {
      if (System.Double.IsNaN(self)) return "Float.nan";
      if (self == System.Double.PositiveInfinity) return "Float.posInf";
      if (self == System.Double.NegativeInfinity) return "Float.negInf";
      return toStr(self) + "f";
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly double m_zero   = 0d;
    public static readonly double m_posInf = System.Double.PositiveInfinity;
    public static readonly double m_negInf = System.Double.NegativeInfinity;
    public static readonly double m_nan    = System.Double.NaN;
    public static readonly double m_e      = Math.E;
    public static readonly double m_pi     = Math.PI;
    public static readonly string m_PosInfStr = "INF";
    public static readonly string m_NegInfStr = "-INF";
    public static readonly string m_NaNStr    = "NaN";

    public static readonly double m_defVal = 0d;

  }
}