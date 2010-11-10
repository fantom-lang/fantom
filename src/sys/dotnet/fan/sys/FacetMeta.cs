//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Nov 10  Brian Frank  Creation
//

using Fanx.Serial;

namespace Fan.Sys
{
  public sealed class FacetMeta : FanObj, Facet
  {
    public static FacetMeta make() { return make(null); }
    public static FacetMeta make(Func func)
    {
      FacetMeta self = new FacetMeta();
      if (func != null)
      {
        func.enterCtor(self);
        func.call(self);
        func.exitCtor();
      }
      return self;
    }

    public override Type @typeof() { return Sys.FacetMetaType; }

    public override string toStr() { return ObjEncoder.encode(this); }

    public bool m_inherited;
  }
}