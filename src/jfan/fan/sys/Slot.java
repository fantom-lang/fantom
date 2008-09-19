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

  public static Method findMethod(Str qname) { return (Method)find(qname.val, true); }
  public static Method findMethod(Str qname, Bool checked) { return (Method)find(qname.val, checked.val); }
  public static Method findMethod(String qname, boolean checked) { return (Method)find(qname, checked); }

  public static Field findField(Str qname) { return (Field)find(qname.val, true); }
  public static Field findField(Str qname, Bool checked) { return (Field)find(qname.val, checked.val); }
  public static Field findField(String qname, boolean checked) { return (Field)find(qname, checked); }

  public static Slot find(Str qname) { return find(qname.val, true); }
  public static Slot find(Str qname, Bool checked) { return find(qname.val, checked.val); }
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

  public static Func findFunc(Str qname) { return findFunc(qname.val, true); }
  public static Func findFunc(Str qname, Bool checked) { return findFunc(qname.val, checked.val); }
  public static Func findFunc(String qname, boolean checked)
  {
    Method m = (Method)find(qname, checked);
    if (m == null) return null;
    return m.func;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public Slot(Type parent, Str name, int flags, Facets facets, int lineNum)
  {
    this.parent  = parent;
    this.name    = name;
    this.qname   = parent == null ? name : Str.make(parent.qname.val + "." + name.val);
    this.flags   = flags;
    this.facets  = facets;
    this.lineNum = lineNum;
  }

  // ctor for Field and Method make()
  Slot()
  {
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.SlotType; }

  public Type parent()   { return parent; }
  public Str name()      { return name; }
  public Str qname()     { return qname; }
  public Bool isField()  { return (this instanceof Field) ? Bool.True : Bool.False; }
  public Bool isMethod() { return (this instanceof Method) ? Bool.True : Bool.False; }
  public abstract Str signature();

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public final int flags() { return flags; }
  public final Bool isAbstract()  { return Bool.make(flags & FConst.Abstract); }
  public /* */ Bool isConst()     { return Bool.make(flags & FConst.Const); } // we let synethic Methods override
  public final Bool isCtor()      { return Bool.make(flags & FConst.Ctor); }
  public final Bool isInternal()  { return Bool.make(flags & FConst.Internal); }
  public final Bool isNative()    { return Bool.make(flags & FConst.Native); }
  public final Bool isOverride()  { return Bool.make(flags & FConst.Override); }
  public final Bool isPrivate()   { return Bool.make(flags & FConst.Private); }
  public final Bool isProtected() { return Bool.make(flags & FConst.Protected); }
  public final Bool isPublic()    { return Bool.make(flags & FConst.Public); }
  public final Bool isStatic()    { return Bool.make(flags & FConst.Static); }
  public final Bool isSynthetic() { return Bool.make(flags & FConst.Synthetic); }
  public final Bool isVirtual()   { return Bool.make(flags & FConst.Virtual); }

  public Obj trap(Str name, List args)
  {
    // private undocumented access
    String n = name.val;
    if (n.equals("flags")) return Int.make(flags);
    if (n.equals("lineNumber")) return Int.make(lineNum);
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public Map facets() { return facets.map(); }
  public Obj facet(Str name) { return facets.get(name, null); }
  public Obj facet(Str name, Obj def) { return facets.get(name, def); }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public Str doc()
  {
    parent.doc();  // ensure parent has loaded documentation
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public Str toStr() { return qname; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  int flags;
  Str name;
  Str qname;
  Type parent;
  Facets facets;
  public Str doc;
  int lineNum;


}
