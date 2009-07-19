//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation (Java)
//   19 Jul 09  Brian Frank  Port to C#
//

using System;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FSymbol is the fcode representation of sys::Symbol.
  /// </summary>
  public sealed class FSymbol
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FSymbol(FPod pod)
    {
      this.pod = pod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Meta IO
  //////////////////////////////////////////////////////////////////////////

    public FSymbol read(FStore.Input input)
    {
      name   = input.u2();
      flags  = input.u4();
      of     = input.u2();
      val    = input.utf();
      attrs  = FAttrs.read(input);
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public FPod pod;        // parent pod
    public int name;        // name index
    public int flags;       // bitmask
    public int of;          // typeRef index
    public string val;      // serialized value
    public FAttrs attrs;    // meta-data attributes

  }
}