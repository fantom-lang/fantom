//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Oct 08  Brian Frank  Creation
//
package fanx.util;

import java.util.*;
import fan.sys.*;

/**
 * FanUtil defines the mappings between the Fan and Java type systems.
 */
public class FanUtil
{

  /**
   * Convert Java class to Fan type.
   */
  public static Type toFanType(Class cls, boolean checked)
  {
    Type t = (Type)javaToFanTypes.get(cls.getName());
    if (t != null) return t;
    if (!checked) return null;
    throw Err.make("Not a Fan type: " + cls.getName()).val;
  }

  private static HashMap javaToFanTypes = new HashMap();
  static
  {
    javaToFanTypes.put("java.lang.Object", Sys.ObjType);
    javaToFanTypes.put("java.lang.Double", Sys.FloatType);
  }

  /**
   * Return if the specified Java class represents an immutable type.
   */
  public static boolean isJavaImmutable(Class cls)
  {
    return javaImmutables.get(cls.getName()) != null;
  }

  private static HashMap javaImmutables = new HashMap();
  static
  {
    javaImmutables.put("java.lang.Double", Boolean.TRUE);
  }

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
   * Given a Fan qname, get the Java class name:
   *   sys::Obj  =>  java.lang.Object
   *   foo::Bar  =>  fan.foo.Bar
   */
  public static String toJavaClassName(String podName, String typeName)
  {
    if (podName.equals("sys"))
    {
      switch (typeName.charAt(0))
      {
        case 'F':
          if (typeName.equals("Float")) return "java.lang.Double";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "java.lang.Object";
          break;
      }
    }
    return "fan." + podName + "." + typeName;
  }

  /**
   * Given a Fan qname, get the Java implementation class name:
   *   sys::Obj   =>  fan.sys.FanObj
   *   sys::Float =>  fan.sys.FanFloat
   *   sys::Obj   =>  fan.sys.FanObj
   */
  public static String toJavaImplClassName(String podName, String typeName)
  {
    if (podName.equals("sys"))
    {
      switch (typeName.charAt(0))
      {
        case 'F':
          if (typeName.equals("Float")) return "fan.sys.FanFloat";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "fan.sys.FanObj";
          break;
      }
    }
    return "fan." + podName + "." + typeName;
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
      switch (typeName.charAt(0))
      {
        case 'F':
          if (typeName.equals("Float")) return "java/lang/Double";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "java/lang/Object";
          break;
      }
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

  /**
   * Given a Java type signature, return the implementation
   * class signature for methods and fields:
   *   java/lang/Object  =>  fan/sys/FanObj
   *   java/lang/Double  =>  fan/sys/FanFloat
   * Anything returns itself.
   */
  public static String toJavaImplSig(String jsig)
  {
    if (jsig.charAt(0) == 'j')
    {
      if (jsig.equals("java/lang/Object")) return "fan/sys/FanObj";
      if (jsig.equals("java/lang/Double")) return "fan/sys/FanFloat";
    }
    return jsig;
  }

}