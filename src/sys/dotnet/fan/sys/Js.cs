//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//

namespace Fan.Sys
{
  public sealed class Js : FanObj, Facet
  {
    public static readonly Js m_defVal = new Js();

    private Js() {}

    public override Type @typeof() { return Sys.JsType; }

    public override string toStr() { return @typeof().qname(); }
  }
}