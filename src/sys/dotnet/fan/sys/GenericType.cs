//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Andy Frank  Creation
//

using System.Collections;
using System.Runtime.CompilerServices;
using Fanx.Fcode;

namespace Fan.Sys
{
  /// <summary>
  /// GenericType is the base class for ListType, MapType, and MethodType
  /// which all support parameterization of the generic parameter types (such
  /// as A-H, V, K).  Instances of GenericType are used to represent generic
  /// instances (for example an instance of ListType is used to represent string[]).
  /// </summary>
  public abstract class GenericType : Type
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal GenericType(Type baseType)
    {
      m_base = baseType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override sealed Pod pod() { return m_base.pod(); }
    public override sealed string name() { return m_base.name(); }
    public override sealed string qname() { return m_base.qname(); }
    public override abstract string signature();
    internal override int flags() { return m_base.flags(); }

    public override sealed Type @base() { return m_base; }
    public override sealed List mixins() { return m_base.mixins(); }
    public override sealed List inheritance() { return m_base.inheritance(); }

    public override bool isGenericInstance() { return true; }

    public override bool @is(Type type)
    {
      if (type == this || type == m_base) return true;
      return m_base.@is(type);
    }

    public override sealed List fields()  { return ((GenericType)reflect()).m_fields.ro(); }
    public override sealed List methods() { return ((GenericType)reflect()).m_methods.ro(); }
    public override sealed List slots()   { return ((GenericType)reflect()).m_slots.ro(); }

    public override sealed Slot slot(string name, bool check)
    {
      Slot slot = (Slot)((GenericType)reflect()).m_slotsByName[name];
      if (slot != null) return slot;
      if (check) throw UnknownSlotErr.make(this.qname() + "." + name).val;
      return null;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public override sealed Type toNullable()
    {
      if (m_nullable == null) m_nullable = new NullableType(this);
      return m_nullable;
    }

    public override Map @params()
    {
      if (m_params == null) m_params = makeParams();
      return m_params;
    }

    internal abstract Map makeParams();

    public override List facets() { return m_base.facets(); }
    public override Facet facet(Type t, bool c) { return m_base.facet(t, c); }

    public override string doc() { return m_base.doc(); }

    public override sealed bool dotnetRepr() { return false; }

  //////////////////////////////////////////////////////////////////////////
  // Reflect
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// On reflection, we parameterize the master's methods.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public override sealed Type reflect()
    {
      if (m_slotsByName != null) return this;
      doReflect();
      return this;
    }

    protected void doReflect()
    {
      // ensure master type is reflected
      Type master = m_base;
      master.finish();
      List masterSlots = master.slots();

      // allocate slot data structures
      m_fields = new List(Sys.FieldType, master.fields().sz());
      m_methods = new List(Sys.MethodType, master.methods().sz());
      m_slots = new List(Sys.SlotType, masterSlots.sz());
      m_slotsByName = new Hashtable(masterSlots.sz()*3);

      // parameterize master's slots
      for (int i=0; i<masterSlots.sz(); i++)
      {
        Slot slot = (Slot)masterSlots.get(i);
        if (slot is Method)
        {
          slot = parameterize((Method)slot);
          m_methods.add(slot);
        }
        else
        {
          slot = parameterize((Field)slot);
          m_fields.add(slot);
        }
        m_slots.add(slot);
        m_slotsByName[slot.m_name] = slot;
      }
    }

    /// <summary>
    /// Parameterize the specified field (reuse if generic
    /// parameterization isn't necessary).
    /// </summary>
    internal Field parameterize(Field f)
    {
      // if not generic, short circuit and reuse original
      Type of = f.type();
      if (!of.isGenericParameter()) return f;

      // create new parameterized version
      of = parameterize(of);
      Field pf = new Field(this, f.m_name, f.m_flags, f.m_facets, f.m_lineNum, of);
      pf.m_reflect = f.m_reflect;
      return pf;
    }

    /// <summary>
    /// Parameterize the specified method (reuse if generic
    /// parameterization isn't necessary).
    /// </summary>
    internal Method parameterize(Method m)
    {
      // if not generic, short circuit and reuse original
      if (!m.isGenericMethod()) return m;

      // new signature
      Func func = m.m_func;
      Type ret;
      List pars = new List(Sys.ParamType, m.m_params.sz());

      // parameterize return type
      if (func.m_returns.isGenericParameter())
        ret = parameterize(func.m_returns);
      else
        ret = func.m_returns;

      // narrow pars (or just reuse if not parameterized)
      for (int i=0; i<m.m_params.sz(); i++)
      {
        Param p = (Param)m.m_params.get(i);
        if (p.m_type.isGenericParameter())
        {
          pars.add(new Param(p.m_name, parameterize(p.m_type), p.m_mask));
        }
        else
        {
          pars.add(p);
        }
      }

      Method pm = new Method(this, m.m_name, m.m_flags, m.m_facets, m.m_lineNum, ret, m.m_inheritedReturns, pars, m);
      pm.m_reflect = m.m_reflect;
      return pm;
    }

    /// <summary>
    /// Parameterize t, where t is a generic parameter type such as V.
    /// </summary>
    internal Type parameterize(Type t)
    {
      bool nullable = t.isNullable();
      Type nn = t.toNonNullable();
      if (nn is ListType)
        t = parameterizeListType((ListType)nn);
      else if (nn is FuncType)
        t = parameterizeFuncType((FuncType)nn);
      else
        t = doParameterize(nn);
      return nullable ? t.toNullable() : t;
    }

    /// <summary>
    /// Recursively parameterize the a generic list type.
    /// </summary>
    internal Type parameterizeListType(ListType t)
    {
      return doParameterize(t.m_v).toListOf();
    }

    /// <summary>
    /// Recursively parameterize the pars of a method type.
    /// </summary>
    internal FuncType parameterizeFuncType(FuncType t)
    {
      Type[] pars = new Type[t.m_params.Length];
      for (int i=0; i<pars.Length; i++)
      {
        Type param = t.m_params[i];
        if (param.isGenericParameter()) param = doParameterize(param);
        pars[i] = param;
      }

      Type ret = t.m_ret;
      if (ret.isGenericParameter()) ret = doParameterize(ret);

      return new FuncType(pars, ret);
    }

    /// <summary>
    /// Parameterize t, where t is a generic parameter type such as V.
    /// </summary>
    protected abstract Type doParameterize(Type t);

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    // available at construction time
    private readonly Type m_base;

    // lazily created by toNullable()
    private Type m_nullable;

    // lazily created by params()
    private Map m_params;

    // available when reflected
    internal List m_fields;
    internal List m_methods;
    internal List m_slots;
    internal Hashtable m_slotsByName;  // string:Slot

  }

}