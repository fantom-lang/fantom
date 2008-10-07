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
  // Comparisions -> Bool
  //////////////////////////////////////////////////////////////////////////

    public static Bool compareEQ(object a, object b)
    {
      if (a == null) return (b == null) ? Bool.True : Bool.False;
      if (b == null) return Bool.False;
      return a.Equals(b) ? Bool.True : Bool.False;
    }

    public static Bool compareNE(object a, object b)
    {
      if (a == null) return (b == null) ? Bool.False : Bool.True;
      if (b == null) return Bool.True;
      return a.Equals(b) ? Bool.False : Bool.True;
    }

    public static Int compare(object a, object b)
    {
      if (a == null) return (b == null) ? Int.EQ : Int.LT;
      if (b == null) return Int.GT;
      return FanObj.compare(a, b);
    }

    public static Bool compareLT(object a, object b)
    {
      if (a == null) return (b == null) ? Bool.False : Bool.True;
      if (b == null) return Bool.False;
      return FanObj.compare(a, b).val < 0 ? Bool.True : Bool.False;
    }

    public static Bool compareLE(object a, object b)
    {
      if (a == null) return Bool.True;
      if (b == null) return Bool.False;
      return FanObj.compare(a, b).val <= 0 ? Bool.True : Bool.False;
    }

    public static Bool compareGE(object a, object b)
    {
      if (a == null) return (b == null) ? Bool.True : Bool.False;
      if (b == null) return Bool.True;
      return FanObj.compare(a, b).val >= 0 ? Bool.True : Bool.False;
    }

    public static Bool compareGT(object a, object b)
    {
      if (a == null) return Bool.False;
      if (b == null) return Bool.True;
      return FanObj.compare(a, b).val > 0 ? Bool.True : Bool.False;
    }

    public static Bool compareSame(object a, object b) // need to use Object for mixins
    {
      return a == b ? Bool.True : Bool.False;
    }

    public static Bool compareNotSame(object a, object b) // need to use Object for mixins
    {
      return a != b ? Bool.True : Bool.False;
    }

    public static Bool compareNull(object a) // need to use Object for mixins
    {
      return a == null ? Bool.True : Bool.False;
    }

    public static Bool compareNotNull(object a) // need to use Object for mixins
    {
      return a != null ? Bool.True : Bool.False;
    }

  //////////////////////////////////////////////////////////////////////////
  // Is/As
  //////////////////////////////////////////////////////////////////////////

    public static Bool @is(object instance, Type type)
    {
      if (instance == null) return Bool.False;
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
      if (FanObj.isImmutable(obj).val) return obj;
      if (obj is List)   return ((List)obj).toImmutable();
      if (obj is Map)    return ((Map)obj).toImmutable();
      throw NotImmutableErr.make(FanObj.type(obj).toStr()).val;
    }

  }
}