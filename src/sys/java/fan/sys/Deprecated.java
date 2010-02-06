//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * Deprecated facet
 */
public final class Deprecated extends FanObj implements Facet
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

  public Type typeof() { return Sys.DeprecatedType; }

  public String toStr() { return ObjEncoder.encode(this); }

  public String msg = "";

}