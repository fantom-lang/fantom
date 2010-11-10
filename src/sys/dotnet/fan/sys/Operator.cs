//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Nov 10  Brian Frank  Creation
//

namespace Fan.Sys
{
  public sealed class Operator  : FanObj, Facet
  {
    public static readonly Operator m_defVal = new Operator();

    private Operator() {}

    public override Type @typeof() { return Sys.OperatorType; }

    public override string toStr() { return @typeof().qname(); }
  }
}