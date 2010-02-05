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
 * Serializable facet
 */
public final class Serializable extends FanObj implements Facet
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

  public Type typeof() { return Sys.SerializableType; }

  public String toStr() { return ObjEncoder.encode(this); }

  public boolean simple;
  public boolean collection;

}