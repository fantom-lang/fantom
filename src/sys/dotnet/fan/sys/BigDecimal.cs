//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Oct 08  Andy Frank  Creation
//

using System.Globalization;

namespace Fan.Sys
{
  ///
  /// Temp wrapper for decimal primitive
  ///
  public sealed class BigDecimal : Number, System.IComparable
  {
    private BigDecimal(decimal val) { this.val = val; }
    private BigDecimal(long val)    { this.val = val; }
    private BigDecimal(double val)  { this.val = (decimal)val; }

    public override bool Equals(object obj)
    {
      if (obj is BigDecimal)
        return val == (obj as BigDecimal).val;
      return false;
    }

    public int CompareTo(object obj)
    {
      decimal that = ((BigDecimal)obj).val;
      if (val < that) return -1;
      if (val > that) return 1;
      return 0;
    }

    public override int GetHashCode() { return val.GetHashCode(); }

    public BigDecimal multiply(BigDecimal that)
    {
      return BigDecimal.valueOf(val * that.val);
    }

    public BigDecimal divide(BigDecimal that)
    {
      return BigDecimal.valueOf(val / that.val);
    }

    public BigDecimal remainder(BigDecimal that)
    {
      return BigDecimal.valueOf(val % that.val);
    }

    public BigDecimal add(BigDecimal that)
    {
      return BigDecimal.valueOf(val + that.val);
    }

    public BigDecimal subtract(BigDecimal that)
    {
      return BigDecimal.valueOf(val - that.val);
    }

    public decimal decimalValue() { return val; }
    public override int intValue() { return (int)val; }
    public override long longValue() { return (long)val; }
    public override float floatValue() { return (float)val; }
    public override double doubleValue() { return (double)val; }

    public static BigDecimal valueOf(decimal m) { return new BigDecimal(m); }
    public static BigDecimal valueOf(long l)    { return new BigDecimal(l); }
    public static BigDecimal valueOf(double d)  { return new BigDecimal(d); }
    public static BigDecimal valueOf(string s)
    {
      return new BigDecimal(decimal.Parse(s,
          NumberStyles.AllowLeadingSign |
          NumberStyles.AllowExponent |
          NumberStyles.AllowDecimalPoint));
    }

    public override string ToString() { return val.ToString(); }
    public static string toString(decimal m) { return new BigDecimal(m).ToString(); }

    private decimal val = 0m;
  }
}