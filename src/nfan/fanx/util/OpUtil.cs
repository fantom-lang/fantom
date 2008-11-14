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
  // Comparisions -> Boolean
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
      return FanObj.compare(a, b) < 0;
    }

    public static bool compareLEz(object a, object b)
    {
      if (a == null) return true;
      if (b == null) return false;
      return FanObj.compare(a, b) <= 0;
    }

    public static bool compareGEz(object a, object b)
    {
      if (a == null) return (b == null);
      if (b == null) return true;
      return FanObj.compare(a, b) >= 0;
    }

    public static bool compareGTz(object a, object b)
    {
      if (a == null) return false;
      if (b == null) return true;
      return FanObj.compare(a, b) > 0;
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

    public static long compare(object a, object b)
    {
      if (a == null) return (b == null) ? 0 : -1;
      if (b == null) return +1;
      return FanObj.compare(a, b);
    }

    public static Boolean compareLT(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.False : Boolean.True;
      if (b == null) return Boolean.False;
      return FanObj.compare(a, b) < 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareLE(object a, object b)
    {
      if (a == null) return Boolean.True;
      if (b == null) return Boolean.False;
      return FanObj.compare(a, b) <= 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareGE(object a, object b)
    {
      if (a == null) return (b == null) ? Boolean.True : Boolean.False;
      if (b == null) return Boolean.True;
      return FanObj.compare(a, b) >= 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareGT(object a, object b)
    {
      if (a == null) return Boolean.False;
      if (b == null) return Boolean.True;
      return FanObj.compare(a, b) > 0 ? Boolean.True : Boolean.False;
    }

    public static Boolean compareSame(object a, object b) // need to use object for mixins
    {
      return a == b ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNotSame(object a, object b) // need to use object for mixins
    {
      return a != b ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNull(object a) // need to use object for mixins
    {
      return a == null ? Boolean.True : Boolean.False;
    }

    public static Boolean compareNotNull(object a) // need to use object for mixins
    {
      return a != null ? Boolean.True : Boolean.False;
    }

  //////////////////////////////////////////////////////////////////////////
  // sys::Bool Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static Boolean compareEQ(Boolean a, Boolean b) { return Boolean.valueOf(a.booleanValue() == b.booleanValue()); }
    public static Boolean compareEQ(Boolean a, object b)  { return (b is Boolean) ? Boolean.valueOf(a.booleanValue() == ((Boolean)b).booleanValue()) : Boolean.False; }
    public static Boolean compareEQ(object a, Boolean b)  { return (a is Boolean) ? Boolean.valueOf(b.booleanValue() == ((Boolean)a).booleanValue()) : Boolean.False; }

    public static Boolean compareNE(Boolean a, Boolean b) { return Boolean.valueOf(a.booleanValue() != b.booleanValue()); }
    public static Boolean compareNE(Boolean a, object b)  { return (b is Boolean) ? Boolean.valueOf(a.booleanValue() != ((Boolean)b).booleanValue()) : Boolean.True; }
    public static Boolean compareNE(object a, Boolean b)  { return (a is Boolean) ? Boolean.valueOf(b.booleanValue() != ((Boolean)a).booleanValue()) : Boolean.True; }

    public static Boolean compareLT(Boolean a, Boolean b) { return a.booleanValue() == b.booleanValue() ? Boolean.False : Boolean.valueOf(!a.booleanValue()); }
    public static Boolean compareLT(Boolean a, object b)  { return (b is Boolean) ? compareLT(a, (Boolean)b) : compareLT((object)a, b); }
    public static Boolean compareLT(object a, Boolean b)  { return (a is Boolean) ? compareLT((Boolean)a, b) : compareLT(a, (object)b); }

    public static Boolean compareLE(Boolean a, Boolean b) { return a.booleanValue() == b.booleanValue() ? Boolean.True : Boolean.valueOf(!a.booleanValue()); }
    public static Boolean compareLE(Boolean a, object b)  { return (b is Boolean) ? compareLE(a, (Boolean)b) : compareLE((object)a, b); }
    public static Boolean compareLE(object a, Boolean b)  { return (a is Boolean) ? compareLE((Boolean)a, b) : compareLE(a, (object)b); }

    public static Boolean compareGE(Boolean a, Boolean b) { return a.booleanValue() == b.booleanValue() ? Boolean.True : a; }
    public static Boolean compareGE(Boolean a, object b)  { return (b is Boolean) ? compareGE(a, (Boolean)b) : compareGE((object)a, b); }
    public static Boolean compareGE(object a, Boolean b)  { return (a is Boolean) ? compareGE((Boolean)a, b) : compareGE(a, (object)b); }

    public static Boolean compareGT(Boolean a, Boolean b) { return a.booleanValue() == b.booleanValue() ? Boolean.False : a; }
    public static Boolean compareGT(Boolean a, object b)  { return (b is Boolean) ? compareGT(a, (Boolean)b) : compareGT((object)a, b); }
    public static Boolean compareGT(object a, Boolean b)  { return (a is Boolean) ? compareGT((Boolean)a, b) : compareGT(a, (object)b); }

    public static long compare(Boolean a, Boolean b) { return a.booleanValue() == b.booleanValue() ? 0 : a.booleanValue() ? +1 : -1; }
    public static long compare(Boolean a, object b)  { return (b is Boolean) ? compare(a, (Boolean)b) : compare((object)a, b); }
    public static long compare(object a, Boolean b)  { return (a is Boolean) ? compare((Boolean)a, b) : compare(a, (object)b); }

  //////////////////////////////////////////////////////////////////////////
  // sys::Int Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static Boolean compareEQ(long a, long b) { return Boolean.valueOf(a == b); }
    public static Boolean compareEQ(long a, object b) { return (b is Long) ? Boolean.valueOf(a == ((Long)b).longValue()) : Boolean.False; }
    public static Boolean compareEQ(object a, long b) { return (a is Long) ? Boolean.valueOf(b == ((Long)a).longValue()) : Boolean.False; }

    public static Boolean compareNE(long a, long b) { return Boolean.valueOf(a != b); }
    public static Boolean compareNE(long a, object b) { return (b is Long) ? Boolean.valueOf(a != ((Long)b).longValue()) : Boolean.True; }
    public static Boolean compareNE(object a, long b) { return (a is Long) ? Boolean.valueOf(b != ((Long)a).longValue()) : Boolean.True; }

    public static Boolean compareLT(long a, long b) { return Boolean.valueOf(a < b); }
    public static Boolean compareLT(long a, object b) { return (b is Long) ? Boolean.valueOf(a < ((Long)b).longValue()) : compareLT((object)a, b); }
    public static Boolean compareLT(object a, long b) { return (a is Long) ? Boolean.valueOf(((Long)a).longValue() < b) : compareLT(a, (object)b); }

    public static Boolean compareLE(long a, long b) { return Boolean.valueOf(a <= b); }
    public static Boolean compareLE(long a, object b) { return (b is Long) ? Boolean.valueOf(a <= ((Long)b).longValue()) : compareLE((object)a, b); }
    public static Boolean compareLE(object a, long b) { return (a is Long) ? Boolean.valueOf(((Long)a).longValue() <= b) : compareLE(a, (object)b); }

    public static Boolean compareGE(long a, long b) { return Boolean.valueOf(a >= b); }
    public static Boolean compareGE(long a, object b) { return (b is Long) ? Boolean.valueOf(a >= ((Long)b).longValue()) : compareGE((object)a, b); }
    public static Boolean compareGE(object a, long b) { return (a is Long) ? Boolean.valueOf(((Long)a).longValue() >= b) : compareGE(a, (object)b); }

    public static Boolean compareGT(long a, long b) { return Boolean.valueOf(a > b); }
    public static Boolean compareGT(long a, object b) { return (b is Long) ? Boolean.valueOf(a > ((Long)b).longValue()) : compareGT((object)a, b); }
    public static Boolean compareGT(object a, long b) { return (a is Long) ? Boolean.valueOf(((Long)a).longValue() > b) : compareGT(a, (object)b); }

    public static long compare(long a, long b) { return a < b ? -1 : (a == b ? 0 : +1); }
    public static long compare(long a, object b) { return (b is Long) ? compare(a, ((Long)b).longValue()) : compare((object)a, b); }
    public static long compare(object a, long b) { return (a is Long) ? compare(((Long)a).longValue(), b) : compare(a, (object)b); }

  //////////////////////////////////////////////////////////////////////////
  // sys::Float Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static Boolean compareEQ(double a, double b) { return Boolean.valueOf(a == b); }
    public static Boolean compareEQ(double a, object b) { return (b is Double) ? compareEQ(a, (b as Double).doubleValue()) : Boolean.False; }
    public static Boolean compareEQ(object a, double b) { return (a is Double) ? compareEQ((a as Double).doubleValue(), b) : Boolean.False; }

    public static Boolean compareNE(double a, double b) { return Boolean.valueOf(a != b); }
    public static Boolean compareNE(double a, object b) { return (b is Double) ? compareNE(a, (b as Double).doubleValue()) : Boolean.True; }
    public static Boolean compareNE(object a, double b) { return (a is Double) ? compareNE((a as Double).doubleValue(), b) : Boolean.True; }

    public static Boolean compareLT(double a, double b) { return Boolean.valueOf(a < b); }
    public static Boolean compareLT(double a, object b) { return (b is Double) ? compareLT(a, (b as Double).doubleValue()) : compareLT((object)a, b); }
    public static Boolean compareLT(object a, double b) { return (a is Double) ? compareLT((a as Double).doubleValue(), b) : compareLT(a, (object)b); }

    public static Boolean compareLE(double a, double b) { return Boolean.valueOf(a <= b); }
    public static Boolean compareLE(double a, object b) { return (b is Double) ? compareLE(a, (b as Double).doubleValue()) : compareLE((object)a, b); }
    public static Boolean compareLE(object a, double b) { return (a is Double) ? compareLE((a as Double).doubleValue(), b) : compareLE(a, (object)b); }

    public static Boolean compareGE(double a, double b) { return Boolean.valueOf(a >= b); }
    public static Boolean compareGE(double a, object b) { return (b is Double) ? compareGE(a, (b as Double).doubleValue()) : compareGE((object)a, b); }
    public static Boolean compareGE(object a, double b) { return (a is Double) ? compareGE((a as Double).doubleValue(), b) : compareGE(a, (object)b); }

    public static Boolean compareGT(double a, double b) { return Boolean.valueOf(a > b); }
    public static Boolean compareGT(double a, object b) { return (b is Double) ? compareGT(a, (b as Double).doubleValue()) : compareGT((object)a, b); }
    public static Boolean compareGT(object a, double b) { return (a is Double) ? compareGT((a as Double).doubleValue(), b) : compareGT(a, (object)b); }

    public static long compare(double a, object b) { return (b is Double) ? compare(a, (b as Double).doubleValue()) : compare((object)a, b); }
    public static long compare(object a, double b) { return (a is Double) ? compare((a as Double).doubleValue(), b) : compare(a, (object)b); }
    public static long compare(double a, double b)
    {
      if (System.Double.IsNaN(a))
      {
        return (System.Double.IsNaN(b)) ? 0 : -1;
      }
      if (System.Double.IsNaN(b)) return +1;
      return a < b ? -1 : (a == b ? 0 : +1);
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

      // TODO - this isn't quite right, need to clean up with FanObj.isImmutable
      if (obj is Double) return ((Double)obj).doubleValue();
      if (obj is Long) return ((Long)obj).longValue();

      if (FanObj.isImmutable(obj).booleanValue()) return obj;
      if (obj is List)   return ((List)obj).toImmutable();
      if (obj is Map)    return ((Map)obj).toImmutable();
      throw NotImmutableErr.make(FanObj.type(obj).toStr()).val;
    }

  }
}