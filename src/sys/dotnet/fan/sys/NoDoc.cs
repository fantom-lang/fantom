//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//

namespace Fan.Sys
{
  public sealed class NoDoc : FanObj, Facet
  {
    public static readonly NoDoc m_defVal = new NoDoc();

    private NoDoc() {}

    public override Type @typeof() { return Sys.NoDocType; }

    public override string toStr() { return @typeof().qname(); }
  }
}