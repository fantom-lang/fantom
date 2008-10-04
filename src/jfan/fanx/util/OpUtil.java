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
// Comparisions -> boolean
//////////////////////////////////////////////////////////////////////////

  public static boolean compareEQz(Object a, Object b)
  {
    if (a == null) return (b == null);
    if (b == null) return false;
    return a.equals(b);
  }

  public static boolean compareNEz(Object a, Object b)
  {
    if (a == null) return (b != null);
    if (b == null) return true;
    return !a.equals(b);
  }

  public static boolean compareLTz(Object a, Object b)
  {
    if (a == null) return (b != null);
    if (b == null) return false;
    return FanObj.compare(a, b).val < 0;
  }

  public static boolean compareLEz(Object a, Object b)
  {
    if (a == null) return true;
    if (b == null) return false;
    return FanObj.compare(a, b).val <= 0;
  }

  public static boolean compareGEz(Object a, Object b)
  {
    if (a == null) return (b == null);
    if (b == null) return true;
    return FanObj.compare(a, b).val >= 0;
  }

  public static boolean compareGTz(Object a, Object b)
  {
    if (a == null) return false;
    if (b == null) return true;
    return FanObj.compare(a, b).val > 0;
  }

//////////////////////////////////////////////////////////////////////////
// Comparisions -> Bool
//////////////////////////////////////////////////////////////////////////

  public static Bool compareEQ(Object a, Object b)
  {
    if (a == null) return (b == null) ? Bool.True : Bool.False;
    if (b == null) return Bool.False;
    return a.equals(b) ? Bool.True : Bool.False;
  }

  public static Bool compareNE(Object a, Object b)
  {
    if (a == null) return (b == null) ? Bool.False : Bool.True;
    if (b == null) return Bool.True;
    return a.equals(b) ? Bool.False : Bool.True;
  }

  public static Int compare(Object a, Object b)
  {
    if (a == null) return (b == null) ? Int.EQ : Int.LT;
    if (b == null) return Int.GT;
    return FanObj.compare(a, b);
  }

  public static Bool compareLT(Object a, Object b)
  {
    if (a == null) return (b == null) ? Bool.False : Bool.True;
    if (b == null) return Bool.False;
    return FanObj.compare(a, b).val < 0 ? Bool.True : Bool.False;
  }

  public static Bool compareLE(Object a, Object b)
  {
    if (a == null) return Bool.True;
    if (b == null) return Bool.False;
    return FanObj.compare(a, b).val <= 0 ? Bool.True : Bool.False;
  }

  public static Bool compareGE(Object a, Object b)
  {
    if (a == null) return (b == null) ? Bool.True : Bool.False;
    if (b == null) return Bool.True;
    return FanObj.compare(a, b).val >= 0 ? Bool.True : Bool.False;
  }

  public static Bool compareGT(Object a, Object b)
  {
    if (a == null) return Bool.False;
    if (b == null) return Bool.True;
    return FanObj.compare(a, b).val > 0 ? Bool.True : Bool.False;
  }

  public static Bool compareSame(Object a, Object b) // need to use Object for mixins
  {
    return a == b ? Bool.True : Bool.False;
  }

  public static Bool compareNotSame(Object a, Object b) // need to use Object for mixins
  {
    return a != b ? Bool.True : Bool.False;
  }

  public static Bool compareNull(Object a) // need to use Object for mixins
  {
    return a == null ? Bool.True : Bool.False;
  }

  public static Bool compareNotNull(Object a) // need to use Object for mixins
  {
    return a != null ? Bool.True : Bool.False;
  }

//////////////////////////////////////////////////////////////////////////
// Is/As
//////////////////////////////////////////////////////////////////////////

  public static Bool is(Object instance, Type type)
  {
    if (instance == null) return Bool.False;
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
    if (FanObj.isImmutable(obj).val) return obj;
    if (obj instanceof List)   return ((List)obj).toImmutable();
    if (obj instanceof Map)    return ((Map)obj).toImmutable();
    throw NotImmutableErr.make(FanObj.type(obj).toStr()).val;
  }

}