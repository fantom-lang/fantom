//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//
package fan.sys;

/**
 * FanObj is the root class of all classes in Fan - it is the class
 * representation of Obj which manifests itself as both an interface
 * called Obj and this class.
 */
public class FanObj
  implements Obj
{

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  public int hashCode()
  {
    long hash = hash().val;
    return (int)(hash ^ (hash >>> 32));
  }

  public final boolean equals(Object obj)
  {
    if (obj instanceof Obj)
      return equals((Obj)obj).val;
    else
      return false;
  }

  public final String toString()
  {
    return toStr().val;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Bool equals(Obj obj)
  {
    return this == obj ? Bool.True : Bool.False;
  }

  public Int compare(Obj obj)
  {
    return toStr().compare(obj.toStr());
  }

  public Int hash()
  {
    return Int.make(super.hashCode());
  }

  public Str toStr()
  {
    return Str.make(super.toString());
  }

  public Bool isImmutable()
  {
    return type().isConst();
  }

  public Type type()
  {
    return Sys.ObjType;
  }

  public Obj trap(Str name, List args)
  {
    Slot slot = type().slot(name, Bool.True);
    if (slot instanceof Method)
    {
      Method m = (Method)slot;
      return m.func.callOn(this, args);
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
  public Obj trapUri(Uri uri)
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
    catch (UnknownSlotErr.Val e)
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
    System.out.println(obj);
  }

}
