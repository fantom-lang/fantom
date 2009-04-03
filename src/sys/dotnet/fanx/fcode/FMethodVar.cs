//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;

namespace Fanx.Fcode
{
  /// <summary>
  /// FMethodVar models one parameter or local variable in a FMethod.
  /// </summary>
  public class FMethodVar
  {

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public bool IsParam() { return (flags & FConst.Param) != 0; }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public FMethodVar read(FStore.Input input)
    {
      name  = input.name();
      type  = input.u2();
      flags = input.u1();

      int attrCount = input.u2();
      for (int i=0; i<attrCount; ++i)
      {
        string attrName = input.fpod.name(input.u2());
        FBuf attrBuf = FBuf.read(input);
        if (attrName == FConst.ParamDefaultAttr)
          def = attrBuf;
      }
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public string name;   // variable name
    public int type;      // type qname index
    public int flags;     // method variable flags
    public FBuf def;      // default expression or null (only for params)

  }
}
