//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor Num into Number/FanNum
//
package fan.sys;

import java.math.*;

/**
 * FanNum defines the methods for sys::Num.  The actual
 * class used for representation is java.lang.Number.
 */
public class FanNum
{

  public static Long toInt(Number self)
  {
    if (self instanceof Long) return (Long)self;
    return Long.valueOf(self.longValue());
  }

  public static Double toFloat(Number self)
  {
    if (self instanceof Double) return (Double)self;
    return Double.valueOf(self.doubleValue());
  }

  public static BigDecimal toDecimal(Number self)
  {
    if (self instanceof BigDecimal) return (BigDecimal)self;
    if (self instanceof Long) return new BigDecimal(self.longValue());
    return new BigDecimal(self.doubleValue());
  }

  public static Type type(Number self) { return Sys.NumType; }

}