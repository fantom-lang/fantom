//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Context
 */
public final class Context
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public Context(Actor actor)
  {
    this.actor = actor;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ContextType; }

//////////////////////////////////////////////////////////////////////////
// Context
//////////////////////////////////////////////////////////////////////////

  public final Actor actor() { return actor; }

  public final Map map() { return map; }

  public final Object get(String name) { return map.get(name); }
  public final Object get(String name, Object def) { return map.get(name, def); }

  public final Context set(String name, Object val) { map.set(name, val); return this; }

  public Object trap(String name, List args)
  {
    if (args.size() == 0)
    {
      Object val = map.get(name);
      if (val != null) return val;
      throw UnknownSlotErr.make("Name not in Context.map: " + name).val;
    }

    if (args.size() == 1)
    {
      Object val = args.first();
      map.set(name, val);
      return val;
    }

    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Actor actor;
  final Map map = new Map(Sys.StrType, Sys.ObjType.toNullable());
  final Map locals = new Map(Sys.StrType, Sys.ObjType.toNullable());
  Locale locale = Locale.cur();
}