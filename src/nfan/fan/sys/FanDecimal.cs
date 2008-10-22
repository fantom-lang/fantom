//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 08  Andy Frank  Creation
//   20 Oct 08  Andy Frank  Refactor BigDecimal into FanDecimal
//

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
    public static BigDecimal fromStr(string s, Boolean check) { return fromStr(s, check.booleanValue()); }
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

    public static Boolean equals(BigDecimal self, object obj)
    {
      if (obj is BigDecimal)
      {
        return self.Equals(obj) ? Boolean.True : Boolean.False;
      }
      return Boolean.False;
    }

    public static Long compare(BigDecimal self, object obj)
    {
      return Long.valueOf(self.CompareTo(obj));
    }

    public static Long hash(BigDecimal self)
    {
      return Long.valueOf(self.GetHashCode());
    }

    public static Type type(BigDecimal self)
    {
      return Sys.DecimalType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static BigDecimal negate    (BigDecimal self)            { return BigDecimal.valueOf(-self.decimalValue()); }
    public static BigDecimal mult      (BigDecimal self, BigDecimal x) { return BigDecimal.valueOf(self.decimalValue() * x.decimalValue()); }
    public static BigDecimal div       (BigDecimal self, BigDecimal x) { return BigDecimal.valueOf(self.decimalValue() / x.decimalValue()); }
    public static BigDecimal mod       (BigDecimal self, BigDecimal x) { return BigDecimal.valueOf(self.decimalValue() % x.decimalValue()); }
    public static BigDecimal plus      (BigDecimal self, BigDecimal x) { return BigDecimal.valueOf(self.decimalValue() + x.decimalValue()); }
    public static BigDecimal minus     (BigDecimal self, BigDecimal x) { return BigDecimal.valueOf(self.decimalValue() - x.decimalValue()); }
    public static BigDecimal increment (BigDecimal self)            { return BigDecimal.valueOf(self.decimalValue()+1); }
    public static BigDecimal decrement (BigDecimal self)            { return BigDecimal.valueOf(self.decimalValue()-1); }

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

  }
}