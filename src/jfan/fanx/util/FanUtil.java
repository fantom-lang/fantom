//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Oct 08  Brian Frank  Creation
//
package fanx.util;

import fan.sys.*;

/**
 * FanUtil defines the mappings between the Fan and Java type systems.
 */
public class FanUtil
{

  /**
   * Convert Java method name to Fan method name.
   */
  public static String toFanMethodName(String name)
  {
    if (name.equals("_equals")) return "equals";
    return name;
  }

  /**
   * Convert Fan method name to Java method name.
   */
  public static String toJavaMethodName(String name)
  {
    if (name.equals("equals")) return "_equals";
    return name;
  }

  /**
   * Given a Fan qname, get the Java type signature:
   *   sys::Obj  =>  java/lang/Object
   *   foo::Bar  =>  fan/foo/Bar
   */
  public static String toJavaTypeSig(String podName, String typeName)
  {
    if (podName.equals("sys"))
    {
      if (typeName.equals("Obj")) return "java/lang/Object";
    }
    return "fan/" + podName + "/" + typeName;
  }

  /**
   * Given a Fan type, get the Java type signature.
   */
  public static String toJavaTypeSig(Type t)
  {
    return toJavaTypeSig(t.pod().name().val, t.name().val);
  }

}