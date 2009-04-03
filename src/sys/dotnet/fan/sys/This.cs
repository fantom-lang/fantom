//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 08  Brian Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// This represents a method return type which is always "this type".
  /// </summary>
  public class This
  {
    public Type type() { return Sys.ThisType; }
  }
}
