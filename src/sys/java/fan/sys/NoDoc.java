//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 10  Brian Frank  Creation
//
package fan.sys;

/**
 * NoDoc facet
 */
public final class NoDoc extends FanObj implements Facet
{
  public static final NoDoc defVal = new NoDoc();

  private NoDoc() {}

  public Type typeof() { return Sys.NoDocType; }

  public String toStr() { return typeof().qname(); }

}