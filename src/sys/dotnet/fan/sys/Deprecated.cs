//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//

using Fanx.Serial;

namespace Fan.Sys
{
  public sealed class Deprecated : FanObj, Facet
  {
    public static Deprecated make() { return make(null); }
    public static Deprecated make(Func func)
    {
      Deprecated self = new Deprecated();
      if (func != null)
      {
        func.enterCtor(self);
        func.call(self);
        func.exitCtor();
      }
      return self;
    }

    public override Type @typeof() { return Sys.DeprecatedType; }

    public override string toStr() { return ObjEncoder.encode(this); }

    public string m_msg = "";
  }
}