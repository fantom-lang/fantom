//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  ///
  /// FanObj is the root class of all classes in Fan - it is the class
  /// representation of Obj which manifests itself as both an interface
  /// called Obj and this class.
  ///
  public class FanObj : Obj
  {

  //////////////////////////////////////////////////////////////////////////
  // .NET
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode()
    {
      long h = hash().val;
      return (int)(h ^ (h >> 32));
    }

    public override bool Equals(Object obj)
    {
      if (obj is Obj)
        return equals((Obj)obj).val;
      else
        return false;
    }

    public override string ToString()
    {
      return toStr().val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public virtual Bool equals(Obj obj)
    {
      return this == obj ? Bool.True : Bool.False;
    }

    public virtual Int compare(Obj obj)
    {
      return toStr().compare(obj.toStr());
    }

    public virtual Int hash()
    {
      return Int.make(base.GetHashCode());
    }

    public virtual Str toStr()
    {
      return Str.make(base.ToString());
    }

    public virtual Bool isImmutable()
    {
      return type().isConst();
    }

    public virtual Type type()
    {
      return Sys.ObjType;
    }

    public virtual Obj trap(Str name, List args)
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
          Obj val = args.get(0);
          f.set(this, val);
          return val;
        }

        throw ArgErr.make("Invalid number of args to get or set field '" + name + "'").val;
      }
    }

    /* TODO
    public virtual Obj trapUri(Uri uri)
    {
      // sanity checks
      List path = uri.path();
      if (path == null) throw ArgErr.make("Path is null: '" + uri + "'").val;

      // if path is empty, return this
      if (path.sz() == 0) return this;

      // get next level of path
      Str nextName = (Str)path.first();
      Obj obj = null;
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

    public static void echo(Obj obj)
    {
      System.Console.WriteLine(obj);
    }
  }
}
