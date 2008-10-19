//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jan 06  Brian Frank  Creation
//
package fanx.util;

import fan.sys.*;

/**
 * OpUtil provides static methods used to implement special fcode opcodes.
 */
public class OpUtil
{

//////////////////////////////////////////////////////////////////////////
// Comparisions -> Bool
//////////////////////////////////////////////////////////////////////////

  public static boolean compareEQ(Object a, Object b)
  {
    if (a == null) return (b == null);
    if (b == null) return false;
    return a.equals(b);
  }

  public static boolean compareNE(Object a, Object b)
  {
    if (a == null) return (b != null);
    if (b == null) return true;
    return !a.equals(b);
  }

  public static long compare(Object a, Object b)
  {
    if (a == null) return (b == null) ? 0L : -1L;
    if (b == null) return +1L;
    return FanObj.compare(a, b);
  }

  public static boolean compareLT(Object a, Object b)
  {
    if (a == null) return (b != null);
    if (b == null) return false;
    return FanObj.compare(a, b) < 0;
  }

  public static boolean compareLE(Object a, Object b)
  {
    if (a == null) return true;
    if (b == null) return false;
    return FanObj.compare(a, b) <= 0;
  }

  public static boolean compareGE(Object a, Object b)
  {
    if (a == null) return (b == null);
    if (b == null) return true;
    return FanObj.compare(a, b) >= 0;
  }

  public static boolean compareGT(Object a, Object b)
  {
    if (a == null) return false;
    if (b == null) return true;
    return FanObj.compare(a, b) > 0;
  }

  public static boolean compareSame(Object a, Object b) // need to use Object for mixins
  {
    return a == b;
  }

  public static boolean compareNotSame(Object a, Object b) // need to use Object for mixins
  {
    return a != b;
  }

  public static boolean compareNull(Object a) // need to use Object for mixins
  {
    return a == null;
  }

  public static boolean compareNotNull(Object a) // need to use Object for mixins
  {
    return a != null;
  }

//////////////////////////////////////////////////////////////////////////
// Is/As
//////////////////////////////////////////////////////////////////////////

  public static boolean is(Object instance, Type type)
  {
    if (instance == null) return false;
    return FanObj.type(instance).fits(type);
  }

  public static Object as(Object instance, Type type)
  {
    if (instance == null) return null;
    return FanObj.type(instance).is(type) ? instance : null;
  }

  public static Object toImmutable(Object obj)
  {
    if (obj == null) return null;
    if (FanObj.isImmutable(obj)) return obj;
    if (obj instanceof List)   return ((List)obj).toImmutable();
    if (obj instanceof Map)    return ((Map)obj).toImmutable();
    throw NotImmutableErr.make(FanObj.type(obj).toStr()).val;
  }

}