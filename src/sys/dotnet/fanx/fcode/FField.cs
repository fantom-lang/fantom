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
  /// FField is the read/write fcode representation of sys::Field.
  /// </summary>
  public class FField : FSlot
  {

    public FField read(FStore.Input input)
    {
      base.readCommon(input);
      m_type = input.u2();
      base.readAttrs(input);
      return this;
    }

    public int m_type;       // type qname index

  }
}
