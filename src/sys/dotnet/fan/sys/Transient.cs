//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//

namespace Fan.Sys
{
  public sealed class Transient : FanObj, Facet
  {
    public static readonly Transient m_defVal = new Transient();

    private Transient() {}

    public override Type @typeof() { return Sys.TransientType; }

    public override string toStr() { return @typeof().qname(); }
  }
}