//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Unsafe
 */
public final class Unsafe
  extends FanObj
{

  public static Unsafe make(Object val) { return new Unsafe(val); }

  public Unsafe(Object val) { this.val = val; }

  public Type typeof() { return Sys.UnsafeType; }

  public Object val() { return val; }

  public boolean isImmutable() { return true; }

  public String toStr() { return "Unsafe(" + val + ")"; }

  private Object val;

}