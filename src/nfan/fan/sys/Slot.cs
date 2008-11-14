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

    public static Method findMethod(string qname) { return (Method)find(qname, true); }
    public static Method findMethod(string qname, Boolean check) { return (Method)find(qname, check.booleanValue()); }
    public static Method findMethod(string qname, bool check) { return (Method)find(qname, check); }

    public static Field findField(string qname) { return (Field)find(qname, true); }
    public static Field findField(string qname, Boolean check) { return (Field)find(qname, check.booleanValue()); }
    public static Field findField(string qname, bool check) { return (Field)find(qname, check); }

    public static Slot find(string qname) { return find(qname, true); }
    public static Slot find(string qname, Boolean check) { return find(qname, check.booleanValue()); }
    public static Slot find(string qname, bool check)
    {
      string typeName, slotName;
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

    public static Func findFunc(string qname) { return findFunc(qname, true); }
    public static Func findFunc(string qname, Boolean check) { return findFunc(qname, check.booleanValue()); }
    public static Func findFunc(string qname, bool check)
    {
      Method m = (Method)find(qname, check);
      if (m == null) return null;
      return m.m_func;
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public Slot(Type parent, string name, int flags, Facets facets, int lineNum)
    {
      this.m_parent  = parent;
      this.m_name    = name;
      this.m_qname   = parent == null ? name : parent.qname() + "." + name;
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
    public virtual string name() { return m_name; }
    public string qname()        { return m_qname; }
    public Boolean isField()     { return (this is Field) ? Boolean.True : Boolean.False; }
    public Boolean isMethod()    { return (this is Method) ? Boolean.True : Boolean.False; }
    public abstract string signature();

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

    public override object trap(string name, List args)
    {
      // private undocumented access
      string n = name;
      if (n == "flags")      return m_flags;
      if (n == "lineNumber") return m_lineNum;
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public Map facets() { return m_facets.map(); }
    public object facet(string name) { return m_facets.get(name, null); }
    public object facet(string name, object def) { return m_facets.get(name, def); }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public string doc()
    {
      //parent.doc();  // ensure parent has loaded documentation
      //return doc;
      return "todo";
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return m_qname; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Type m_parent;
    internal string m_name;
    internal string m_qname;
    internal int m_flags;
    internal Facets m_facets;
    public string m_doc;
    internal int m_lineNum;

  }
}