//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Oct 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  ///
  /// Temp wrapper for long primitive
  ///
  public sealed class Long : Number, System.IComparable
  {
    private Long(long val)
    {
      this.val = val;
    }

    public override bool Equals(object obj)
    {
      if (obj is Long)
        return val == (obj as Long).val;
      return false;
    }

    public int CompareTo(object obj)
    {
      long that = ((Long)obj).val;
      if (val < that) return -1;
      if (val > that) return 1;
      return 0;
    }

    public override int GetHashCode() { return val.GetHashCode(); }

    public override int intValue() { return (int)val; }
    public override long longValue() { return val; }
    public override float floatValue() { return (float)val; }
    public override double doubleValue() { return (double)val; }

    public static Long valueOf(string s) { return valueOf(System.Int64.Parse(s)); }
    public static Long valueOf(long l)
    {
      if (l >= -100 && l <= 155)
        return intern[l+100];
      return new Long(l);
    }

    public override string ToString() { return val.ToString(); }
    public static string toString(long l) { return new Long(l).ToString(); }

    private long val = 0;

    private static Long[] intern = new Long[356];  // -100 to 256
    static Long()
    {
      for (int i=0; i<intern.Length; i++)
        intern[i] = new Long(-100 + i);
    }
  }
}