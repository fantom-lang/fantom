//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 06  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Num is the base class for numbers including Int and Float.
  /// </summary>
  public abstract class Num : FanObj
  {

    public abstract Int toInt();

    public abstract Float toFloat();

    public abstract Decimal toDecimal();

    public override Type type() { return Sys.NumType; }

  }
}