//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using Fanx.Fcode;

namespace Fan.Sys
{
  /// <summary>
  /// Slot models a member field or method of a Type.
  /// </summary>
  public abstract class Slot : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Method findMethod(Str qname) { return (Method)find(qname.val, true); }
    public static Method findMethod(Str qname, Boolean check) { return (Method)find(qname.val, check.booleanValue()); }
    public static Method findMethod(String qname, bool check) { return (Method)find(qname, check); }

    public static Field findField(Str qname) { return (Field)find(qname.val, true); }
    public static Field findField(Str qname, Boolean check) { return (Field)find(qname.val, check.booleanValue()); }
    public static Field findField(String qname, bool check) { return (Field)find(qname, check); }

    public static Slot find(Str qname) { return find(qname.val, true); }
    public static Slot find(Str qname, Boolean check) { return find(qname.val, check.booleanValue()); }
    public static Slot find(String qname, bool check)
    {
      String typeName, slotName;
      try
      {
        int dot = qname.IndexOf('.');
        typeName = qname.Substring(0, dot);
        slotName = qname.Substring(dot+1);
      }
      catch (Exception)
      {
        throw Err.make("Invalid slot qname \"" + qname + "\", use <pod>::<type>.<slot>").val;
      }
      Type type = Type.find(typeName, check);
      if (type == null) return null;
      return type.slot(slotName, check);
    }

    public static Func findFunc(Str qname) { return findFunc(qname.val, true); }
    public static Func findFunc(Str qname, Boolean check) { return findFunc(qname.val, check.booleanValue()); }
    public static Func findFunc(string qname, bool check)
    {
      Method m = (Method)find(qname, check);
      if (m == null) return null;
      return m.m_func;
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public Slot(Type parent, Str name, int flags, Facets facets, int lineNum)
    {
      this.m_parent  = parent;
      this.m_name    = name;
      this.m_qname   = parent == null ? name : Str.make(parent.m_qname.val + "." + name.val);
      this.m_flags   = flags;
      this.m_facets  = facets;
      this.m_lineNum = lineNum;
    }

    // ctor for Field and Method make()
    internal Slot()
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.SlotType; }

    public Type parent()      { return m_parent; }
    public virtual Str name() { return m_name; }
    public Str qname()        { return m_qname; }
    public Boolean isField()     { return (this is Field) ? Boolean.True : Boolean.False; }
    public Boolean isMethod()    { return (this is Method) ? Boolean.True : Boolean.False; }
    public abstract Str signature();

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public int flags() { return m_flags; }
    public Boolean isAbstract()  { return Boolean.valueOf(m_flags & FConst.Abstract); }
public virtual Boolean isConst() { return Boolean.valueOf(m_flags & FConst.Const); } // we let synethic Methods override
    public Boolean isCtor()      { return Boolean.valueOf(m_flags & FConst.Ctor); }
    public Boolean isFinal()     { return Boolean.valueOf(m_flags & FConst.Final); }
    public Boolean isInternal()  { return Boolean.valueOf(m_flags & FConst.Internal); }
    public Boolean isNative()    { return Boolean.valueOf(m_flags & FConst.Native); }
    public Boolean isOverride()  { return Boolean.valueOf(m_flags & FConst.Override); }
    public Boolean isPrivate()   { return Boolean.valueOf(m_flags & FConst.Private); }
    public Boolean isProtected() { return Boolean.valueOf(m_flags & FConst.Protected); }
    public Boolean isPublic()    { return Boolean.valueOf(m_flags & FConst.Public); }
    public Boolean isStatic()    { return Boolean.valueOf(m_flags & FConst.Static); }
    public Boolean isSynthetic() { return Boolean.valueOf(m_flags & FConst.Synthetic); }
    public Boolean isVirtual()   { return Boolean.valueOf(m_flags & FConst.Virtual); }

    public override object trap(Str name, List args)
    {
      // private undocumented access
      string n = name.val;
      if (n == "flags") return Int.make(m_flags);
      if (n == "lineNumber") return Int.make(m_lineNum);
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public Map facets() { return m_facets.map(); }
    public object facet(Str name) { return m_facets.get(name, null); }
    public object facet(Str name, object def) { return m_facets.get(name, def); }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public Str doc()
    {
      //parent.doc();  // ensure parent has loaded documentation
      //return doc;
      return Str.make("todo");
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr() { return m_qname; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Type m_parent;
    internal Str m_name;
    internal Str m_qname;
    internal int m_flags;
    internal Facets m_facets;
    public Str m_doc;
    internal int m_lineNum;

  }
}