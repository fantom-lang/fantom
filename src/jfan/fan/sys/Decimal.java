//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Apr 08  Brian Frank  Creation
//
package fan.sys;

import java.math.*;
import fanx.serial.*;

/**
 * Decimal
 */
public final class Decimal
  extends Num
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Decimal fromStr(Str s) { return fromStr(s.val, true); }
  public static Decimal fromStr(Str s, Boolean checked) { return fromStr(s.val, checked); }
  public static Decimal fromStr(String s, boolean checked)
  {
    try
    {
      return make(new BigDecimal(s));
    }
    catch (NumberFormatException e)
    {
      if (!checked) return null;
      throw ParseErr.make("Decimal",  s).val;
    }
  }

  public static Decimal make(BigDecimal val)
  {
    return new Decimal(val);
  }

  private Decimal(BigDecimal val) { this.val = val; }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Boolean _equals(Object obj)
  {
    if (obj instanceof Decimal)
    {
      return val.equals(((Decimal)obj).val);
    }
    return false;
  }

  public Long compare(Object obj)
  {
    return Long.valueOf(val.compareTo(((Decimal)obj).val));
  }

  public int hashCode()
  {
    return val.hashCode();
  }

  public Long hash()
  {
    return Long.valueOf(val.hashCode());
  }

  public Type type()
  {
    return Sys.DecimalType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public Decimal negate() { return make(val.negate()); }
  public Decimal mult      (Decimal x) { return make(val.multiply(x.val)); }
  public Decimal div       (Decimal x) { return make(val.divide(x.val)); }
  public Decimal mod       (Decimal x) { return make(val.remainder(x.val)); }
  public Decimal plus      (Decimal x) { return make(val.add(x.val)); }
  public Decimal minus     (Decimal x) { return make(val.subtract(x.val)); }
  public Decimal increment ()          { return make(val.add(BigDecimal.ONE)); }
  public Decimal decrement ()          { return make(val.subtract(BigDecimal.ONE)); }

//////////////////////////////////////////////////////////////////////////
// Num
//////////////////////////////////////////////////////////////////////////

  public Long toInt() { return Long.valueOf(val.longValue()); }

  public Double toFloat() { return Double.valueOf(val.doubleValue()); }

  public Decimal toDecimal() { return this; }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  public Decimal abs()
  {
    BigDecimal absVal = val.abs();
    if (absVal == val) return this;
    return make(absVal);
  }

  public Decimal min(Decimal that)
  {
    if (val.compareTo(that.val) <= 0) return this;
    return that;
  }

  public Decimal max(Decimal that)
  {
    if (val.compareTo(that.val) >= 0) return this;
    return that;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public Str toStr()
  {
    return Str.make(val.toString());
  }

  public void encode(ObjEncoder out)
  {
    out.w(val.toString()).w("d");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final BigDecimal val;

}
