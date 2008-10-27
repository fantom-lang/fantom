//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;
using Fanx.Util;

namespace Fan.Sys
{
  ///
  /// FanObj is the root class of all classes in Fan - it is the class
  /// representation of Obj which manifests itself as both an interface
  /// called Obj and this class.
  ///
  public class FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // .NET
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode()
    {
      long h = hash().longValue();
      return (int)(h ^ (h >> 32));
    }

    public override bool Equals(object obj)
    {
      return _equals(obj).booleanValue();
    }

    public override string ToString()
    {
      return toStr();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Boolean equals(object self, object x)
    {
      if (self is FanObj)
        return ((FanObj)self)._equals(x);
      else
        return Boolean.valueOf(self.Equals(x));
    }

    public virtual Boolean _equals(object obj)
    {
      return this == obj ? Boolean.True : Boolean.False;
    }

    public static Long compare(object self, object x)
    {
      if (self is FanObj)
        return ((FanObj)self).compare(x);
      else if (self is string)
        return FanStr.compare((string)self, x);
      else if (self is IComparable)
        return Long.valueOf(((IComparable)self).CompareTo(x));
      else
        return FanStr.compare(toStr(self), toStr(x));
    }

    public virtual Long compare(object obj)
    {
      return FanStr.compare(toStr(), toStr(obj));
    }

    public static Long hash(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).hash();
      else
        return Long.valueOf(self.GetHashCode());
    }

    public virtual Long hash()
    {
      return Long.valueOf(base.GetHashCode());
    }

    public static string toStr(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).toStr();
      else
        return self.ToString();
    }

    public virtual string toStr()
    {
      return base.ToString();
    }

    public static Boolean isImmutable(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).isImmutable();
      else
        return Boolean.valueOf(FanUtil.isNetImmutable(self.GetType()));
    }

    public virtual Boolean isImmutable()
    {
      return type().isConst();
    }

    public static Type type(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).type();
      else
        return FanUtil.toFanType(self.GetType(), true);
    }

    public virtual Type type()
    {
      return Sys.ObjType;
    }

    public static object trap(object self, string name, List args)
    {
      if (self is FanObj)
        return ((FanObj)self).trap(name, args);
      else
        return doTrap(self, name, args, type(self));
    }

    public virtual object trap(string name, List args) { return doTrap(this, name, args, type()); }

    private static object doTrap(object self, string name, List args, Type type)
    {
      Slot slot = type.slot(name, Boolean.True);
      if (slot is Method)
      {
        Method m = (Method)slot;
        return m.m_func.callOn(self, args);
      }
      else
      {
        Field f = (Field)slot;
        int argSize = (args == null) ? 0 : args.sz();
        if (argSize == 0)
        {
          return f.get(self);
        }

        if (argSize == 1)
        {
          object val = args.get(0);
          f.set(self, val);
          return val;
        }

        throw ArgErr.make("Invalid number of args to get or set field '" + name + "'").val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static void echo(object obj)
    {
      System.Console.WriteLine(obj);
    }
  }
}