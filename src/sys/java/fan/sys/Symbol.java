//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation
//
package fan.sys;

import fanx.fcode.*;
import fanx.serial.*;

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

  public Symbol(Pod pod, FSymbol fsymbol)
  {
    this.pod    = pod;
    this.name   = pod.fpod.name(fsymbol.name);
    this.qname  = pod.name() + "::" + name;
    this.of     = pod.findType(fsymbol.of);
    this.defVal = initVal(fsymbol.val);
  }

//////////////////////////////////////////////////////////////////////////
// Symbol Methods
//////////////////////////////////////////////////////////////////////////

  public Pod pod() { return pod; }

  public String qname() { return qname; }

  public String name() { return name; }

  public Type of() { return of; }

  public long hash()  { return qname.hashCode(); }

  public boolean equals(Object that)  { return this == that; }

  public String toStr()  { return qname;  }

  public Type type()  { return Sys.SymbolType;  }

//////////////////////////////////////////////////////////////////////////
// Value Management
//////////////////////////////////////////////////////////////////////////

  public Object val() { return defVal(); }

  public Object defVal()
  {
    // if already decoded return it
    if (!(defVal instanceof EncodedVal)) return defVal;

    // decode value
    Object result = decodeVal((EncodedVal)defVal);

    // if immutable we can cache it
    if (FanObj.isImmutable(result)) defVal = result;

    return result;
  }

  /**
   * Convert fcode utf string into a symbol or facet value.
   * Objects which are easy to detect as immutable we immediately
   * decode, others are stored via an EncodedVal wrapper.
   */
  public static Object initVal(String str)
  {
    try
    {
      int ch = str.charAt(0);
      if (ch == '"' || ch == '`' || '0' <= ch && ch <= '9')
        return ObjDecoder.decode(str);
    }
    catch (Exception e)
    {
      System.out.println("Symbol.initVal: " + str);
      e.printStackTrace();
    }
    return new EncodedVal(str);
  }

  /**
   * Given an immutable object or EncodedVal object return
   * its Fan object value.  If the value is immutable then it
   * should be cached for future use.
   */
  private static Object decodeVal(EncodedVal encodedVal)
  {
    // decode into an object
    Object obj = ObjDecoder.decode(encodedVal.str);

    // if list or map try to make it immutable for caching
    if (obj instanceof List)
    {
      List list = (List)obj;
      if (list.of().isConst()) return list.toImmutable();
    }
    if (obj instanceof Map)
    {
      Map map = (Map)obj;
      MapType mapType = (MapType)map.type();
      if (mapType.v.isConst()) return map.toImmutable();
    }

    // this object is not safe for caching
    return obj;
  }

    static class EncodedVal
  {
    EncodedVal(String str) { this.str = str; }
    public String toString() { return str; }
    String str;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Pod pod;
  final String name;
  final String qname;
  final Type of;
  Object defVal;  // immutable Object or EncodedVal

}