//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Oct 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  ///
  /// Temp wrapper for numberic primitives
  ///
  public abstract class Number
  {
    public abstract double doubleValue();
    public abstract float floatValue();
    public abstract int intValue();
    public abstract long longValue();
  }
}