//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Nov 10  Brian Frank  Creation
//
package fan.sys;

/**
 * Operator facet
 */
public final class Operator extends FanObj implements Facet
{
  public static final Operator defVal = new Operator();

  private Operator() {}

  public Type typeof() { return Sys.OperatorType; }

  public String toStr() { return typeof().qname(); }

}