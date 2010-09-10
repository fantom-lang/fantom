//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 10  Brian Frank  Creation
//
package fan.sys;

/**
 * JavaFacet wraps a Java annotation as a Fantom annotation
 */
public final class JavaFacet extends FanObj implements Facet
{
  JavaFacet(JavaType typeof, String string)
  {
    this.typeof = typeof;
    this.string = string;
  }

  public Type typeof()
  {
    return typeof;
  }

  public String toStr()
  {
    String s = typeof.qname();
    if (string.length() > 0) s += " " + string;
    return s;
  }

  private final JavaType typeof;
  private final String string;

}