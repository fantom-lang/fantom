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
  /// FSlot is the read/write fcode representation of sys::Slot.
  /// </summary>
  public class FSlot
  {
    public bool isStatic() { return (m_flags & FConst.Static) != 0; }

    protected void readCommon(FStore.Input input)
    {
      m_name  = input.name();
      m_flags = input.u4();
    }

    protected void readAttrs(FStore.Input input)
    {
      m_attrs = FAttrs.read(input);
    }

    public string m_name;   // simple slot name
    public int m_flags;     // bitmask
    public FAttrs m_attrs;  // meta-data
  }
}