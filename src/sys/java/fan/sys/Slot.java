//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

import fanx.fcode.*;

/**
 * Slot models a member field or method of a Type.
 */
public abstract class Slot
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public static Method findMethod(String qname) { return (Method)find(qname, true); }
  public static Method findMethod(String qname, boolean checked) { return (Method)find(qname, checked); }

  public static Field findField(String qname) { return (Field)find(qname, true); }
  public static Field findField(String qname, boolean checked) { return (Field)find(qname, checked); }

  public static Slot find(String qname) { return find(qname, true); }
  public static Slot find(String qname, boolean checked)
  {
    String typeName, slotName;
    try
    {
      int dot = qname.indexOf('.');
      typeName = qname.substring(0, dot);
      slotName = qname.substring(dot+1);
    }
    catch (Exception e)
    {
      throw Err.make("Invalid slot qname \"" + qname + "\", use <pod>::<type>.<slot>").val;
    }
    Type type = Type.find(typeName, checked);
    if (type == null) return null;
    return type.slot(slotName, checked);
  }

  public static Func findFunc(String qname) { return findFunc(qname, true); }
  public static Func findFunc(String qname, boolean checked)
  {
    Method m = (Method)find(qname, checked);
    if (m == null) return null;
    return m.func;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public Slot(Type parent, String name, int flags, Facets facets, int lineNum)
  {
    this.parent  = parent;
    this.name    = name;
    this.qname   = parent == null ? name : parent.qname() + "." + name;
    this.flags   = flags;
    this.facets  = facets;
    this.lineNum = lineNum;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.SlotType; }

  public Type parent()   { return parent; }
  public String name()      { return name; }
  public String qname()     { return qname; }
  public boolean isField()  { return this instanceof Field; }
  public boolean isMethod() { return this instanceof Method; }
  public abstract String signature();

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public final int flags() { return flags; }
  public final boolean isAbstract()  { return (flags & FConst.Abstract) != 0; }
  public /* */ boolean isConst()     { return (flags & FConst.Const) != 0; } // we let synethic Methods override
  public final boolean isCtor()      { return (flags & FConst.Ctor) != 0; }
  public final boolean isInternal()  { return (flags & FConst.Internal) != 0; }
  public final boolean isNative()    { return (flags & FConst.Native) != 0; }
  public final boolean isOverride()  { return (flags & FConst.Override) != 0; }
  public final boolean isPrivate()   { return (flags & FConst.Private) != 0; }
  public final boolean isProtected() { return (flags & FConst.Protected) != 0; }
  public final boolean isPublic()    { return (flags & FConst.Public) != 0; }
  public final boolean isStatic()    { return (flags & FConst.Static) != 0; }
  public final boolean isSynthetic() { return (flags & FConst.Synthetic) != 0; }
  public final boolean isVirtual()   { return (flags & FConst.Virtual) != 0; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("flags")) return Long.valueOf(flags);
    if (name.equals("lineNumber")) return Long.valueOf(lineNum);
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public List facets() { return facets.list(); }
  public Facet facet(Type t) { return facets.get(t, true); }
  public Facet facet(Type t, boolean c) { return facets.get(t, c); }
  public final boolean hasFacet(Type t) { return facet(t, false) != null; }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public String doc()
  {
    parent.doc();  // ensure parent has loaded documentation
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return qname; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final int flags;
  final String name;
  final String qname;
  Type parent;
  final Facets facets;
  public String doc;
  int lineNum;


}