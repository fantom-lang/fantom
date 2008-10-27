//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 06  Andy Frank  Creation
//   20 Oct 08  Andy Frank  Refactor Num into FanNum
//

namespace Fan.Sys
{
  /// <summary>
  /// FanNum defines the methods for sys::Num.  The actual
  /// class used for representation is Fan.Sys.Number.
  /// </summary>
  public abstract class FanNum
  {

    public static Long toInt(Number self)
    {
      if (self is Long) return (Long)self;
      return Long.valueOf(self.longValue());
    }

    public static Double toFloat(Number self)
    {
      if (self is Double) return (Double)self;
      return Double.valueOf(self.doubleValue());
    }

    public static BigDecimal toDecimal(Number self)
    {
      if (self is BigDecimal) return (BigDecimal)self;
      if (self is Long) return BigDecimal.valueOf(self.longValue());
      return BigDecimal.valueOf(self.doubleValue());
    }

    public static Type type(Number self) { return Sys.NumType; }

  }
}