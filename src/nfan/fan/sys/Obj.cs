//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  ///
  /// Obj is the root type for all classes and mixins in Fan.  It's an interface
  /// so that it can handle mixin interfaces.  The root class is FanObj.
  ///
  public interface Obj
  {

    Bool equals(Obj obj);

    Int compare(Obj obj);

    Int hash();

    Str toStr();

    Bool isImmutable();

    Type type();

    Obj trap(Str name, List args);

  }
}
