//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Apr 08  Brian Frank  Creation
//    4 Oct 08  Brian Frank  Refactor Decimal into BigDecimal/FanDecimal
//
package fan.sys;

import java.math.*;
import fanx.serial.*;

/**
 * FanDecimal defines the methods for sys::Decimal.  The actual
 * class used for representation is java.math.BigDecimal.
 */
public final class FanDecimal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static BigDecimal fromStr(String s) { return fromStr(s, true); }
  public static BigDecimal fromStr(String s, Boolean checked) { return fromStr(s, checked.booleanValue()); }
  public static BigDecimal fromStr(String s, boolean checked)
  {
    try
    {
      return new BigDecimal(s);
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("Decimal",  s).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static Boolean equals(BigDecimal self, Object obj)
  {
    if (obj instanceof BigDecimal)
    {
      return self.equals(obj);
    }
    return false;
  }

  public static Long compare(BigDecimal self, Object obj)
  {
    return Long.valueOf(self.compareTo((BigDecimal)obj));
  }

  public static Long hash(BigDecimal self)
  {
    return Long.valueOf(self.hashCode());
  }

  public static Type type()
  {
    return Sys.DecimalType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public static BigDecimal negate(BigDecimal self)
  {
    return self.negate();
  }

  public static BigDecimal mult(BigDecimal self, BigDecimal x)
  {
    return self.multiply(x);
  }

  public static BigDecimal div(BigDecimal self, BigDecimal x)
  {
    return self.divide(x);
  }

  public static BigDecimal mod(BigDecimal self, BigDecimal x)
  {
    return self.remainder(x);
  }

  public static BigDecimal plus(BigDecimal self, BigDecimal x)
  {
    return self.add(x);
  }

  public static BigDecimal minus(BigDecimal self, BigDecimal x)
  {
    return self.subtract(x);
  }

  public static BigDecimal increment(BigDecimal self)
  {
    return self.add(BigDecimal.ONE);
  }

  public static BigDecimal decrement(BigDecimal self)
  {
    return self.subtract(BigDecimal.ONE);
  }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public static BigDecimal abs(BigDecimal self)
  {
    return self.abs();
  }

  public static BigDecimal min(BigDecimal self, BigDecimal that)
  {
    if (self.compareTo(that) <= 0) return self;
    return that;
  }

  public static BigDecimal max(BigDecimal self, BigDecimal that)
  {
    if (self.compareTo(that) >= 0) return self;
    return that;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static String toStr(BigDecimal self)
  {
    return self.toString();
  }

  public static void encode(BigDecimal self, ObjEncoder out)
  {
    out.w(self.toString()).w("d");
  }

}