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
    // TODO: optimize performance
    Type t = (Type)javaToFanTypes.get(cls.getName());
    if (t != null) return t;
    if (!checked) return null;
    throw Err.make("Not a Fan type: " + cls.getName()).val;
  }

  private static HashMap javaToFanTypes = new HashMap();
  static
  {
    if (Sys.ObjType == null) java.lang.Thread.dumpStack();
    javaToFanTypes.put("boolean",              Sys.BoolType);
    //javaToFanTypes.put("long",                 Sys.IntType);
    //javaToFanTypes.put("double",               Sys.FloatType);
    javaToFanTypes.put("java.lang.Object",     Sys.ObjType);
    javaToFanTypes.put("java.lang.Boolean",    Sys.BoolType);
    javaToFanTypes.put("java.lang.String",     Sys.StrType);
    javaToFanTypes.put("java.lang.Number",     Sys.NumType);
    javaToFanTypes.put("java.lang.Long",       Sys.IntType);
    javaToFanTypes.put("java.lang.Double",     Sys.FloatType);
    javaToFanTypes.put("java.math.BigDecimal", Sys.DecimalType);
  }

  /**
   * Return if the specified Java class represents an immutable type.
   */
  public static boolean isJavaImmutable(Class cls)
  {
    // TODO: optimize performance
    return javaImmutables.get(cls.getName()) != null;
  }

  private static HashMap javaImmutables = new HashMap();
  static
  {
    javaImmutables.put("java.lang.Boolean",    Boolean.TRUE);
    javaImmutables.put("java.lang.String",     Boolean.TRUE);
    javaImmutables.put("java.lang.Long",       Boolean.TRUE);
    javaImmutables.put("java.lang.Double",     Boolean.TRUE);
    javaImmutables.put("java.math.BigDecimal", Boolean.TRUE);
  }

  /**
   * Return if the Fan Type is represented as a Java class
   * such as sys::Int as java.lang.Long.
   */
  public static boolean isJavaRepresentation(Type t)
  {
    if (t.pod() != Sys.SysPod) return false;
    return t == Sys.ObjType   ||
           t == Sys.BoolType  ||
           t == Sys.StrType   ||
           t == Sys.IntType   ||
           t == Sys.FloatType ||
           t == Sys.NumType   ||
           t == Sys.DecimalType;
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
        case 'B':
          if (typeName.equals("Bool")) return "java.lang.Boolean";
          break;
        case 'D':
          if (typeName.equals("Decimal")) return "java.math.BigDecimal";
          break;
        case 'F':
          if (typeName.equals("Float")) return "java.lang.Double";
          break;
        case 'I':
          if (typeName.equals("Int")) return "java.lang.Long";
          break;
        case 'N':
          if (typeName.equals("Num")) return "java.lang.Number";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "java.lang.Object";
          break;
        case 'S':
          if (typeName.equals("Str")) return "java.lang.String";
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
        case 'B':
          if (typeName.equals("Bool")) return "fan.sys.FanBool";
          break;
        case 'D':
          if (typeName.equals("Decimal")) return "fan.sys.FanDecimal";
          break;
        case 'F':
          if (typeName.equals("Float")) return "fan.sys.FanFloat";
          break;
        case 'I':
          if (typeName.equals("Int")) return "fan.sys.FanInt";
          break;
        case 'N':
          if (typeName.equals("Num")) return "fan.sys.FanNum";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "fan.sys.FanObj";
          break;
        case 'S':
          if (typeName.equals("Str")) return "fan.sys.FanStr";
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
  public static String toJavaTypeSig(String podName, String typeName, boolean nullable)
  {
    if (podName.equals("sys"))
    {
      switch (typeName.charAt(0))
      {
        case 'B':
          if (typeName.equals("Bool"))
            return nullable ? "java/lang/Boolean" : "Z";
          break;
        case 'D':
          if (typeName.equals("Decimal")) return "java/math/BigDecimal";
          break;
        case 'F':
          if (typeName.equals("Float")) return "java/lang/Double";
          break;
        case 'I':
          if (typeName.equals("Int")) return "java/lang/Long";
          break;
        case 'N':
          if (typeName.equals("Num")) return "java/lang/Number";
          break;
        case 'O':
          if (typeName.equals("Obj")) return "java/lang/Object";
          break;
        case 'S':
          if (typeName.equals("Str")) return "java/lang/String";
          break;
        case 'V':
          if (typeName.equals("Void")) return "V";
          break;
      }
    }
    return "fan/" + podName + "/" + typeName;
  }

  /**
   * Given a Fan type, get the Java type signature:
   *   fan/sys/Duration
   */
  public static String toJavaTypeSig(Type t)
  {
    return toJavaTypeSig(t.pod().name(), t.name(), t.isNullable());
  }

  /**
   * Given a Fan type, get the Java member signature.
   *   Lfan/sys/Duration;
   */
  public static String toJavaMemberSig(Type t)
  {
    String sig = toJavaTypeSig(t);
    if (sig.length() == 1) return sig;
    return "L" + sig + ";";
  }

  /**
   * Given a Fan type, get its stack type: 'A', 'I', 'J', etc
   */
  public static int toJavaStackType(Type t)
  {
    if (!t.isNullable())
    {
      if (t == Sys.BoolType) return 'I';
      if (t == Sys.VoidType) return 'V';
    }
    return 'A';
  }

  /**
   * Given a Java type signature, return the implementation
   * class signature for methods and fields:
   *   java/lang/Object  =>  fan/sys/FanObj
   *   java/lang/Long    =>  fan/sys/FanInt
   * Anything returns itself.
   */
  public static String toJavaImplSig(String jsig)
  {
    if (jsig.length() == 1)
    {
      switch (jsig.charAt(0))
      {
        case 'Z': return "fan/sys/FanBool";
        default: throw new IllegalStateException(jsig);
      }
    }

    if (jsig.charAt(0) == 'j')
    {
      if (jsig.equals("java/lang/Object"))  return "fan/sys/FanObj";
      if (jsig.equals("java/lang/Boolean")) return "fan/sys/FanBool";
      if (jsig.equals("java/lang/String"))  return "fan/sys/FanStr";
      if (jsig.equals("java/lang/Long"))    return "fan/sys/FanInt";
      if (jsig.equals("java/lang/Double"))  return "fan/sys/FanFloat";
      if (jsig.equals("java/lang/Number"))  return "fan/sys/FanNum";
      if (jsig.equals("java/math/BigDecimal")) return "fan/sys/FanDecimal";
    }
    return jsig;
  }

}