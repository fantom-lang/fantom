//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Oct 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  ///
  /// Temp wrapper for double primitive
  ///
  public sealed class Double : Number, System.IComparable
  {
    public Double(double val)
    {
      this.val = val;
    }

    public override bool Equals(object obj)
    {
      if (!(obj is Double)) return false;
      double x = (obj as Double).val;
      if (System.Double.IsNaN(val)) return System.Double.IsNaN(x);
      return val == x;
    }

    public int CompareTo(object obj)
    {
      double that = ((Double)obj).val;
      if (Double.isNaN(val))
      {
        if (Double.isNaN(that)) return 0;
        if (System.Double.IsPositiveInfinity(that)) return 1;
        if (System.Double.IsNegativeInfinity(that)) return 1;
        return -1;
      }
      else if (Double.isNaN(that))
      {
        return 1;
      }
      else
      {
        if (val < that) return -1; return val == that ? 0 : 1;
      }
    }

    public override int GetHashCode() { return val.GetHashCode(); }

    public override double doubleValue() { return val; }
    public override float floatValue() { return (float)val; }
    public override long longValue()
    {
      if (System.Double.IsNaN(val)) return 0;
      if (val == System.Double.PositiveInfinity) return System.Int64.MaxValue;
      if (val == System.Double.NegativeInfinity) return System.Int64.MinValue;
      return (long)val;
    }
    public override int intValue() { return (int)val; }

    public bool isNaN() { return System.Double.IsNaN(val); }
    public static bool isNaN(double d) { return System.Double.IsNaN(d); }

    public static Double valueOf(double d) { return new Double(d); }
    public static Double valueOf(string s) { return new Double(System.Double.Parse(s)); }
    public static double parseDouble(string s) { return Double.valueOf(s).val; }

    public override string ToString()
    {
      if (System.Double.IsNaN(val)) return FanFloat.m_NaNStr;
      if (val == System.Double.PositiveInfinity) return FanFloat.m_PosInfStr;
      if (val == System.Double.NegativeInfinity) return FanFloat.m_NegInfStr;
      string s = val.ToString();
      if (s.IndexOf('.') == -1 && s.IndexOf("E") == -1) s += ".0";  // to match java behavior
      return s;
    }
    public static string toString(double d) { return new Double(d).ToString(); }

    private double val = 0;
  }
}