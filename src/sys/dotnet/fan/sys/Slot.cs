//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using Fanx.Fcode;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Slot models a member field or method of a Type.
  /// </summary>
  public abstract class Slot : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Method findMethod(string qname) { return (Method)find(qname, true); }
    public static Method findMethod(string qname, bool check) { return (Method)find(qname, check); }

    public static Field findField(string qname) { return (Field)find(qname, true); }
    public static Field findField(string qname, bool check) { return (Field)find(qname, check); }

    public static Slot find(string qname) { return find(qname, true); }
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

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.SlotType; }

    public Type parent()      { return m_parent; }
    public virtual string name() { return m_name; }
    public string qname()        { return m_qname; }
    public bool isField()     { return (this is Field); }
    public bool isMethod()    { return (this is Method); }
    public abstract string signature();

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public int flags() { return m_flags; }
    public bool isAbstract()  { return (m_flags & FConst.Abstract)  != 0; }
public virtual bool isConst() { return (m_flags & FConst.Const)     != 0; } // we let synethic Methods override
    public bool isCtor()      { return (m_flags & FConst.Ctor)      != 0; }
    public bool isFinal()     { return (m_flags & FConst.Final)     != 0; }
    public bool isInternal()  { return (m_flags & FConst.Internal)  != 0; }
    public bool isNative()    { return (m_flags & FConst.Native)    != 0; }
    public bool isOverride()  { return (m_flags & FConst.Override)  != 0; }
    public bool isPrivate()   { return (m_flags & FConst.Private)   != 0; }
    public bool isProtected() { return (m_flags & FConst.Protected) != 0; }
    public bool isPublic()    { return (m_flags & FConst.Public)    != 0; }
    public bool isStatic()    { return (m_flags & FConst.Static)    != 0; }
    public bool isSynthetic() { return (m_flags & FConst.Synthetic) != 0; }
    public bool isVirtual()   { return (m_flags & FConst.Virtual)   != 0; }

    public override object trap(string name, List args)
    {
      // private undocumented access
      string n = name;
      if (n == "flags")      return Long.valueOf(m_flags);
      if (n == "lineNumber") return Long.valueOf(m_lineNum);
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public List facets() { return m_facets.list(); }
    public Facet facet(Type t) { return m_facets.get(t, true); }
    public Facet facet(Type t, bool c) { return m_facets.get(t, c); }
    public bool hasFacet(Type t) { return facet(t, false) != null; }

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

    public void encode(ObjEncoder @out)
    {
      m_parent.encode(@out); @out.w(m_name);
    }

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