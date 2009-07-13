//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation
//
package fan.sys;

import fanx.fcode.*;

/**
 * Symbol is a qualified name/value pair.
 */
public final class Symbol
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  public static Symbol find(String qname) { return find(qname, true); }
  public static Symbol find(String qname, boolean checked)
  {
    String podName, name;
    try
    {
      int colon = qname.indexOf(':');
      if (qname.charAt(colon+1) != ':') throw new Exception();
      podName = qname.substring(0, colon);
      name = qname.substring(colon+2);
    }
    catch (Exception e)
    {
      throw Err.make("Invalid symbol qname \"" + qname + "\", use <pod>::<name>").val;
    }
    Pod pod = Pod.find(podName, checked);
    if (pod == null) return null;
    return pod.symbol(name, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  public Symbol(Pod pod, String name, Type of, Object defVal)
  {
    this.pod = pod;
    this.qname = pod.name() + "::" + name;
    this.name = name;
    this.of = of;
    this.defVal = defVal;
  }

//////////////////////////////////////////////////////////////////////////
// Symbol Methods
//////////////////////////////////////////////////////////////////////////

  public Pod pod() { return pod; }

  public String qname() { return qname; }

  public String name() { return name; }

  public Type of() { return of; }

  public Object val() { return defVal; }

  public Object defVal() { return defVal; }

  public long hash()  { return qname.hashCode(); }

  public boolean equals(Object that)  { return this == that; }

  public String toStr()  { return qname;  }

  public Type type()  { return Sys.SymbolType;  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Pod pod;
  final String name;
  final String qname;
  final Type of;
  final Object defVal;

}