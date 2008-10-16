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
      long h = hash().val;
      return (int)(h ^ (h >> 32));
    }

    public override bool Equals(object obj)
    {
      return _equals(obj).val;
    }

    public override string ToString()
    {
      return toStr().val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Bool equals(object self, object x)
    {
      if (self is FanObj)
        return ((FanObj)self)._equals(x);
      else
        return Bool.make(self.Equals(x));
    }

    public virtual Bool _equals(object obj)
    {
      return this == obj ? Bool.True : Bool.False;
    }

    public static Int compare(object self, object x)
    {
      if (self is FanObj)
        return ((FanObj)self).compare(x);
      else if (self is IComparable)
        return Int.make(((IComparable)self).CompareTo(x));
      else
        return toStr(self).compare(toStr(x));
    }

    public virtual Int compare(object obj)
    {
      return toStr(this).compare(toStr(obj));
    }

    public static Int hash(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).hash();
      else
        return Int.make(self.GetHashCode());
    }

    public virtual Int hash()
    {
      return Int.make(base.GetHashCode());
    }

    public static Str toStr(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).toStr();
      else
        return Str.make(self.ToString());
    }

    public virtual Str toStr()
    {
      return Str.make(base.ToString());
    }

    public static Bool isImmutable(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).isImmutable();
      else
        return Bool.make(NameUtil.isNetImmutable(self.GetType()));
    }

    public virtual Bool isImmutable()
    {
      return type().isConst();
    }

    public static Type type(object self)
    {
      if (self is FanObj)
        return ((FanObj)self).type();
      else
        return NameUtil.toFanType(self.GetType(), true);
    }

    public virtual Type type()
    {
      return Sys.ObjType;
    }

    public static object trap(object self, Str name, List args)
    {
      return ((FanObj)self).trap(name, args);
    }

    public virtual object trap(Str name, List args)
    {
      Slot slot = type().slot(name, Bool.True);
      if (slot is Method)
      {
        Method m = (Method)slot;
        return m.m_func.callOn(this, args);
      }
      else
      {
        Field f = (Field)slot;
        int argSize = (args == null) ? 0 : args.sz();
        if (argSize == 0)
        {
          return f.get(this);
        }

        if (argSize == 1)
        {
          object val = args.get(0);
          f.set(this, val);
          return val;
        }

        throw ArgErr.make("Invalid number of args to get or set field '" + name + "'").val;
      }
    }

    /* TODO
    public virtual object trapUri(Uri uri)
    {
      // sanity checks
      List path = uri.path();
      if (path == null) throw ArgErr.make("Path is null: '" + uri + "'").val;

      // if path is empty, return this
      if (path.sz() == 0) return this;

      // get next level of path
      Str nextName = (Str)path.first();
      object obj = null;
      try
      {
        if (emptyList == null) emptyList = new List(Sys.ObjType).ro();
        obj = trap(nextName, emptyList);
      }
      catch(UnknownSlotErr.Val)
      {
      }
      if (obj == null) return null;

      // recurse
      return obj.trapUri(uri.tail());
    }
    private static List emptyList;
    */

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static void echo(object obj)
    {
      System.Console.WriteLine(obj);
    }
  }
}