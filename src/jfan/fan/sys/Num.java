//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//
package fan.sys;

/**
 * Num is the base class for numbers including Int and Float.
 */
public abstract class Num
  extends FanObj
{

  public abstract Int toInt();

  public abstract Double toFloat();

  public abstract Decimal toDecimal();

  public Type type() { return Sys.NumType; }

}
