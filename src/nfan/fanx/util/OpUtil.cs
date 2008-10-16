//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Oct 06  Andy Frank  Creation
//

using Fan.Sys;

namespace Fanx.Util
{
  /// <summary>
  /// OpUtil provides static methods used to implement special fcode opcodes.
  /// </summary>
  public class OpUtil
  {

  //////////////////////////////////////////////////////////////////////////
  // Comparisions -> boolean
  //////////////////////////////////////////////////////////////////////////

    public static bool compareEQz(object a, object b)
    {
      if (a == null) return (b == null);
      if (b == null) return false;
      return a.Equals(b);
    }

    public static bool compareNEz(object a, object b)
    {
      if (a == null) return (b != null);
      if (b == null) return true;
      return !a.Equals(b);
    }

    public static bool compareLTz(object a, object b)
    {
      if (a == null) return (b != null);
      if (b == null) return false;
      return FanObj.compare(a, b).val < 0;
    }

    public static bool compareLEz(object a, object b)
    {
      if (a == null) return true;
      if (b == null) return false;
      return FanObj.compare(a, b).val <= 0;
    }

    public static bool compareGEz(object a, object b)
    {
      if (a == null) return (b == null);
      if (b == null) return true;
      return FanObj.compare(a, b).val >= 0;
    }

    public static bool compareGTz(object a, object b)
    {
      if (a == null) return false;
      if (b == null) return true;
      return FanObj.compare(a, b).val > 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Comparisions -> Boolean
  //////////////////////////////////////////////////////////////////////////

    public static Boolean compareEQ(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.True : Boolean.False;
      if (b == null) return Boolean.False;
      return a.Equals(b) ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNE(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.False : Boolean.True;
      if (b == null) return Boolean.True;
      return a.Equals(b) ? Boolean.False : Boolean.True;
    }

    public static Int compare(object a, object b)
    {
      if (a == null) return (b == null) ? Int.EQ : Int.LT;
      if (b == null) return Int.GT;
      return FanObj.compare(a, b);
    }

    public static Boolean compareLT(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.False : Boolean.True;
      if (b == null) return Boolean.False;
      return FanObj.compare(a, b).val < 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareLE(object a, object b)
    {
      if (a == null) return Boolean.True;
      if (b == null) return Boolean.False;
      return FanObj.compare(a, b).val <= 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareGE(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.True : Boolean.False;
      if (b == null) return Boolean.True;
      return FanObj.compare(a, b).val >= 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareGT(object a, object b)
    {
      if (a == null) return Boolean.False;
      if (b == null) return Boolean.True;
      return FanObj.compare(a, b).val > 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareSame(object a, object b) // need to use Object for mixins
    {
      return a == b ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNotSame(object a, object b) // need to use Object for mixins
    {
      return a != b ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNull(object a) // need to use Object for mixins
    {
      return a == null ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNotNull(object a) // need to use Object for mixins
    {
      return a != null ? Boolean.True : Boolean.False;
    }

  //////////////////////////////////////////////////////////////////////////
  // Is/As
  //////////////////////////////////////////////////////////////////////////

    public static Boolean @is(object instance, Type type)
    {
      if (instance == null) return Boolean.False;
      return FanObj.type(instance).fits(type);
    }

    public static object @as(object instance, Type type)
    {
      if (instance == null) return null;
      return FanObj.type(instance).@is(type) ? instance : null;
    }

    public static object toImmutable(object obj)
    {
      if (obj == null) return null;
      if (FanObj.isImmutable(obj).booleanValue()) return obj;
      if (obj is List)   return ((List)obj).toImmutable();
      if (obj is Map)    return ((Map)obj).toImmutable();
      throw NotImmutableErr.make(FanObj.type(obj).toStr()).val;
    }

  }
}