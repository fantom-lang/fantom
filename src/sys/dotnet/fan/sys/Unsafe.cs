//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 09  Brian Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// Unsafe
  /// </summary>
  public class Unsafe : FanObj
  {
    public static Unsafe make(object val) { return new Unsafe(val); }

    public Unsafe(object val) { this.m_val = val; }

    public override Type @typeof() { return Sys.UnsafeType; }

    public object val() { return m_val; }

    public override bool isImmutable() { return true; }

    private object m_val;
  }
}