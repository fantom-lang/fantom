//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 08  Andy Frank  Creation
//   20 Oct 08  Andy Frank  Refactor BigDecimal into FanDecimal
//

using System.Globalization;
using Fanx.Serial;

namespace Fan.Sys
{
  ////<summary>
  /// FanDecimal defines the methods for Fan.Sys.BigDecimal.  The actual
  /// class used for representation is Fan.Sys.BigDecimal
  /// </summary>
  public sealed class FanDecimal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static BigDecimal fromStr(string s) { return fromStr(s, true); }
    public static BigDecimal fromStr(string s, bool check)
    {
      try
      {
        return BigDecimal.valueOf(s);
      }
      catch (System.FormatException)
      {
        if (!check) return null;
        throw ParseErr.make("BigDecimal",  s).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static bool equals(BigDecimal self, object obj)
    {
      if (obj is BigDecimal)
      {
        return self.Equals(obj);
      }
      return false;
    }

    public static long compare(BigDecimal self, object obj)
    {
      return self.CompareTo(obj);
    }

    public static long hash(BigDecimal self)
    {
      return self.GetHashCode();
    }

    public static Type type(BigDecimal self)
    {
      return Sys.DecimalType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static BigDecimal negate    (BigDecimal self)            { return BigDecimal.valueOf(-self.decimalValue()); }
    public static BigDecimal increment (BigDecimal self)            { return BigDecimal.valueOf(self.decimalValue()+1); }
    public static BigDecimal decrement (BigDecimal self)            { return BigDecimal.valueOf(self.decimalValue()-1); }

    public static BigDecimal mult(BigDecimal self, BigDecimal x) { return self.multiply(x); }
    public static BigDecimal multInt(BigDecimal self, long x) { return self.multiply(BigDecimal.valueOf(x)); }
    public static BigDecimal multFloat(BigDecimal self, double x) { return self.multiply(BigDecimal.valueOf(x)); }

    public static BigDecimal div(BigDecimal self, BigDecimal x) { return self.divide(x); }
    public static BigDecimal divInt(BigDecimal self, long x) { return self.divide(BigDecimal.valueOf(x)); }
    public static BigDecimal divFloat(BigDecimal self, double x) { return self.divide(BigDecimal.valueOf(x)); }

    public static BigDecimal mod(BigDecimal self, BigDecimal x) { return self.remainder(x); }
    public static BigDecimal modInt(BigDecimal self, long x) { return self.remainder(BigDecimal.valueOf(x)); }
    public static BigDecimal modFloat(BigDecimal self, double x) { return self.remainder(BigDecimal.valueOf(x)); }

    public static BigDecimal plus(BigDecimal self, BigDecimal x) { return self.add(x); }
    public static BigDecimal plusInt(BigDecimal self, long x) { return self.add(BigDecimal.valueOf(x)); }
    public static BigDecimal plusFloat(BigDecimal self, double x) { return self.add(BigDecimal.valueOf(x)); }

    public static BigDecimal minus(BigDecimal self, BigDecimal x) { return self.subtract(x); }
    public static BigDecimal minusInt(BigDecimal self, long x) { return self.subtract(BigDecimal.valueOf(x)); }
    public static BigDecimal minusFloat(BigDecimal self, double x) { return self.subtract(BigDecimal.valueOf(x)); }

  //////////////////////////////////////////////////////////////////////////
  // Math
  //////////////////////////////////////////////////////////////////////////

    public static BigDecimal abs(BigDecimal self)
    {
      return (self.decimalValue() >= 0) ? self : BigDecimal.valueOf(-self.decimalValue());
    }

    public static BigDecimal min(BigDecimal self, BigDecimal that)
    {
      if (self.CompareTo(that) <= 0) return self;
      return that;
    }

    public static BigDecimal max(BigDecimal self, BigDecimal that)
    {
      if (self.CompareTo(that) >= 0) return self;
      return that;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static string toStr(BigDecimal self)
    {
      return self.ToString();
    }

    public static void encode(BigDecimal self, ObjEncoder @out)
    {
      @out.w(self.ToString()).w("d");
    }

    public static string toCode(BigDecimal self)
    {
      return self.ToString() + "d";
    }

    public static string toLocale(BigDecimal self) { return toLocale(self, null); }
    public static string toLocale(BigDecimal self, string pattern)
    {
      // get current locale
      Locale locale = Locale.cur();
      NumberFormatInfo df = locale.dec();

      // get default pattern if necessary
      if (pattern == null)
        pattern = Env.cur().locale(Sys.m_sysPod, "decimal", "#,###.0##");

      // parse pattern and get digits
      NumPattern p = NumPattern.parse(pattern);
      NumDigits d = new NumDigits(self);

      // route to common FanNum method
      return FanNum.toLocale(p, d, df);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly BigDecimal m_defVal = BigDecimal.valueOf(0m);

  }
}