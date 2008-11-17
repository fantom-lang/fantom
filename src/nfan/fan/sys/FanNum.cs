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

    public static long toInt(Number self)
    {
      //if (self is long) return (long)self;
      return self.longValue();
    }

    public static double toFloat(Number self)
    {
      //if (self is double) return self;
      return self.doubleValue();
    }

    public static BigDecimal toDecimal(Number self)
    {
      if (self is BigDecimal) return (BigDecimal)self;
      //if (self is Long) return BigDecimal.valueOf(self.longValue());
      return BigDecimal.valueOf(self.doubleValue());
    }

    public static Type type(Number self) { return Sys.NumType; }

  }
}