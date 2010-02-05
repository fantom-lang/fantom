//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//
package fan.sys;

/**
 * Js facet
 */
public final class Js extends FanObj implements Facet
{
  public static final Js defVal = new Js();

  private Js() {}

  public Type typeof() { return Sys.JsType; }

  public String toStr() { return typeof().qname(); }

}