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
  // Object Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static bool compareEQ(object a, object b)
    {
      if (a == null) return (b == null);
      return a.Equals(b);
    }

    public static bool compareNE(object a, object b)
    {
      if (a == null) return (b != null);
      return !a.Equals(b);
    }

    public static long compare(object a, object b)
    {
      if (a == null) return (b == null) ? 0 : -1;
      if (b == null) return +1;
      return FanObj.compare(a, b);
    }

    public static bool compareLT(object a, object b)
    {
      if (a == null) return (b == null) ? false : true;
      if (b == null) return false;
      return FanObj.compare(a, b) < 0 ? true : false;
    }

    public static bool compareLE(object a, object b)
    {
      if (a == null) return true;
      if (b == null) return false;
      return FanObj.compare(a, b) <= 0 ? true : false;
    }

    public static bool compareGE(object a, object b)
    {
      if (a == null) return (b == null) ? true : false;
      if (b == null) return true;
      return FanObj.compare(a, b) >= 0 ? true : false;
    }

    public static bool compareGT(object a, object b)
    {
      if (a == null) return false;
      if (b == null) return true;
      return FanObj.compare(a, b) > 0 ? true : false;
    }

    ///*
    public static bool compareSame(object a, object b) // need to use object for mixins
    {
      return a == b ? true : false;
    }

    public static bool compareNotSame(object a, object b) // need to use object for mixins
    {
      return a != b ? true : false;
    }

    public static bool compareNull(object a) // need to use object for mixins
    {
      return a == null ? true : false;
    }

    public static bool compareNotNull(object a) // need to use object for mixins
    {
      return a != null ? true : false;
    }
    //*/

  //////////////////////////////////////////////////////////////////////////
  // sys::Bool Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static bool compareEQ(bool a, bool b) { return a == b; }
    public static bool compareEQ(bool a, object b)  { return (b is Boolean) ? a == ((Boolean)b).booleanValue() : false; }
    public static bool compareEQ(object a, bool b)  { return (a is Boolean) ? b == ((Boolean)a).booleanValue() : false; }

    public static bool compareNE(bool a, bool b) { return a != b; }
    public static bool compareNE(bool a, object b)  { return (b is Boolean) ? a != ((Boolean)b).booleanValue() : true; }
    public static bool compareNE(object a, bool b)  { return (a is Boolean) ? b != ((Boolean)a).booleanValue() : true; }

    public static bool compareLT(bool a, bool b) { return a == b ? false : !a; }
    public static bool compareLT(bool a, object b)  { return (b is Boolean) ? compareLT(a, ((Boolean)b).booleanValue()) : compareLT((object)a, b); }
    public static bool compareLT(object a, bool b)  { return (a is Boolean) ? compareLT(((Boolean)a).booleanValue(), b) : compareLT(a, (object)b); }

    public static bool compareLE(bool a, bool b) { return a == b ? true : !a; }
    public static bool compareLE(bool a, object b)  { return (b is Boolean) ? compareLE(a, ((Boolean)b).booleanValue()) : compareLE((object)a, b); }
    public static bool compareLE(object a, bool b)  { return (a is Boolean) ? compareLE(((Boolean)a).booleanValue(), b) : compareLE(a, (object)b); }

    public static bool compareGE(bool a, bool b) { return a == b ? true : a; }
    public static bool compareGE(bool a, object b)  { return (b is Boolean) ? compareGE(a, ((Boolean)b).booleanValue()) : compareGE((object)a, b); }
    public static bool compareGE(object a, bool b)  { return (a is Boolean) ? compareGE(((Boolean)a).booleanValue(), b) : compareGE(a, (object)b); }

    public static bool compareGT(bool a, bool b) { return a == b ? false : a; }
    public static bool compareGT(bool a, object b)  { return (b is Boolean) ? compareGT(a, ((Boolean)b).booleanValue()) : compareGT((object)a, b); }
    public static bool compareGT(object a, bool b)  { return (a is Boolean) ? compareGT(((Boolean)a).booleanValue(), b) : compareGT(a, (object)b); }

    public static long compare(bool a, bool b) { return a == b ? 0 : a ? +1 : -1; }
    public static long compare(bool a, object b)  { return (b is Boolean) ? compare(a, ((Boolean)b).booleanValue()) : compare((object)a, b); }
    public static long compare(object a, bool b)  { return (a is Boolean) ? compare(((Boolean)a).booleanValue(), b) : compare(a, (object)b); }

  //////////////////////////////////////////////////////////////////////////
  // sys::Int Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static bool compareEQ(long a, long b) { return a == b; }
    public static bool compareEQ(long a, object b) { return (b is Long) ? a == ((Long)b).longValue() : false; }
    public static bool compareEQ(object a, long b) { return (a is Long) ? b == ((Long)a).longValue() : false; }

    public static bool compareNE(long a, long b) { return a != b; }
    public static bool compareNE(long a, object b) { return (b is Long) ? a != ((Long)b).longValue() : true; }
    public static bool compareNE(object a, long b) { return (a is Long) ? b != ((Long)a).longValue() : true; }

    public static bool compareLT(long a, long b) { return a < b; }
    public static bool compareLT(long a, object b) { return (b is Long) ? a < ((Long)b).longValue() : compareLT((object)a, b); }
    public static bool compareLT(object a, long b) { return (a is Long) ? ((Long)a).longValue() < b : compareLT(a, (object)b); }

    public static bool compareLE(long a, long b) { return a <= b; }
    public static bool compareLE(long a, object b) { return (b is Long) ? a <= ((Long)b).longValue() : compareLE((object)a, b); }
    public static bool compareLE(object a, long b) { return (a is Long) ? ((Long)a).longValue() <= b : compareLE(a, (object)b); }

    public static bool compareGE(long a, long b) { return a >= b; }
    public static bool compareGE(long a, object b) { return (b is Long) ? a >= ((Long)b).longValue() : compareGE((object)a, b); }
    public static bool compareGE(object a, long b) { return (a is Long) ? ((Long)a).longValue() >= b : compareGE(a, (object)b); }

    public static bool compareGT(long a, long b) { return a > b; }
    public static bool compareGT(long a, object b) { return (b is Long) ? a > ((Long)b).longValue() : compareGT((object)a, b); }
    public static bool compareGT(object a, long b) { return (a is Long) ? ((Long)a).longValue() > b : compareGT(a, (object)b); }

    public static long compare(long a, long b) { return a < b ? -1 : (a == b ? 0 : +1); }
    public static long compare(long a, object b) { return (b is Long) ? compare(a, ((Long)b).longValue()) : compare((object)a, b); }
    public static long compare(object a, long b) { return (a is Long) ? compare(((Long)a).longValue(), b) : compare(a, (object)b); }

  //////////////////////////////////////////////////////////////////////////
  // sys::Float Comparisions
  //////////////////////////////////////////////////////////////////////////

    public static bool compareEQ(double a, double b) { return a == b; }
    public static bool compareEQ(double a, object b) { return (b is Double) ? compareEQ(a, (b as Double).doubleValue()) : false; }
    public static bool compareEQ(object a, double b) { return (a is Double) ? compareEQ((a as Double).doubleValue(), b) : false; }

    public static bool compareNE(double a, double b) { return a != b; }
    public static bool compareNE(double a, object b) { return (b is Double) ? compareNE(a, (b as Double).doubleValue()) : true; }
    public static bool compareNE(object a, double b) { return (a is Double) ? compareNE((a as Double).doubleValue(), b) : true; }

    public static bool compareLT(double a, double b) { return a < b; }
    public static bool compareLT(double a, object b) { return (b is Double) ? compareLT(a, (b as Double).doubleValue()) : compareLT((object)a, b); }
    public static bool compareLT(object a, double b) { return (a is Double) ? compareLT((a as Double).doubleValue(), b) : compareLT(a, (object)b); }

    public static bool compareLE(double a, double b) { return a <= b; }
    public static bool compareLE(double a, object b) { return (b is Double) ? compareLE(a, (b as Double).doubleValue()) : compareLE((object)a, b); }
    public static bool compareLE(object a, double b) { return (a is Double) ? compareLE((a as Double).doubleValue(), b) : compareLE(a, (object)b); }

    public static bool compareGE(double a, double b) { return a >= b; }
    public static bool compareGE(double a, object b) { return (b is Double) ? compareGE(a, (b as Double).doubleValue()) : compareGE((object)a, b); }
    public static bool compareGE(object a, double b) { return (a is Double) ? compareGE((a as Double).doubleValue(), b) : compareGE(a, (object)b); }

    public static bool compareGT(double a, double b) { return a > b; }
    public static bool compareGT(double a, object b) { return (b is Double) ? compareGT(a, (b as Double).doubleValue()) : compareGT((object)a, b); }
    public static bool compareGT(object a, double b) { return (a is Double) ? compareGT((a as Double).doubleValue(), b) : compareGT(a, (object)b); }

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

    public static bool @is(object instance, Type type)
    {
      if (instance == null) return false;
      return FanObj.@typeof(instance).fits(type);
    }

    public static object toImmutable(object obj)
    {
      if (obj == null) return null;

      // TODO - this isn't quite right, need to clean up with FanObj.isImmutable
      if (obj is Double) return ((Double)obj).doubleValue();
      if (obj is Long) return ((Long)obj).longValue();

      if (FanObj.isImmutable(obj)) return obj;
      if (obj is List)   return ((List)obj).toImmutable();
      if (obj is Map)    return ((Map)obj).toImmutable();
      throw NotImmutableErr.make(FanObj.@typeof(obj).toStr()).val;
    }

  }
}