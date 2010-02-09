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
  public sealed class Serializable : FanObj, Facet
  {
    public static Serializable make() { return make(null); }
    public static Serializable make(Func func)
    {
      Serializable self = new Serializable();
      if (func != null)
      {
        func.enterCtor(self);
        func.call(self);
        func.exitCtor();
      }
      return self;
    }

    public override Type @typeof() { return Sys.SerializableType; }

    public override string toStr() { return ObjEncoder.encode(this); }

    public bool m_simple;
    public bool m_collection;
  }
}