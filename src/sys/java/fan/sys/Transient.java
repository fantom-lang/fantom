//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//
package fan.sys;

/**
 * Transient facet
 */
public final class Transient extends FanObj implements Facet
{
  public static final Transient defVal = new Transient();

  private Transient() {}

  public Type typeof() { return Sys.TransientType; }

  public String toStr() { return typeof().qname(); }

}