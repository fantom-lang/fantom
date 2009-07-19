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
      long h = hash();
      return (int)(h ^ (h >> 32));
    }

    public override string ToString()
    {
      return toStr();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static bool equals(object self, object x)
    {
      return self.Equals(x);
    }

    public static long compare(object self, object x)
    {
      if (self is FanObj)
        return ((FanObj)self).compare(x);
      else if (self is string)
        return FanStr.compare((string)self, x);
      else if (self is IComparable)
        return ((IComparable)self).CompareTo(x);
      else
        return FanStr.compare(toStr(self), toStr(x));
    }

    public virtual long compare(object obj)
    {
      return FanStr.compare(toStr(), toStr(obj));
    }

    public static long hash(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).hash();
      else
        return self.GetHashCode();
    }

    public virtual long hash()
    {
      return base.GetHashCode();
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

    public static bool isImmutable(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).isImmutable();
      else if (self == null)
        return true;
      else
        return FanUtil.isDotnetImmutable(self.GetType());
    }

    public virtual bool isImmutable()
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

    public static object with(object self, Func f)
    {
      if (self is FanObj)
      {
        return ((FanObj)self).with(f);
      }
      else
      {
        f.call(self);
        return self;
      }
    }

    public virtual object with(Func f) { f.call(this); return this; }

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
      Slot slot = type.slot(name, true);
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
          return FanUtil.box(f.get(self));
        }

        if (argSize == 1)
        {
          object val = args.get(0);
          f.set(self, val);
          return FanUtil.box(val);
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