//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Andy Frank  Creation
//

using System.Collections;
using Fanx.Fcode;

namespace Fan.Sys
{
  /// <summary>
  /// GenericType is the base class for ListType, MapType, and MethodType
  /// which all support parameterization of the generic parameter types (such
  /// as A-H, V, K).  Instances of GenericType are used to represent generic
  /// instances (for example an instance of ListType is used to represent string[]).
  /// </summary>
  public abstract class GenericType : ClassType
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal GenericType(Type baseType) :
      base(baseType.pod(), baseType.name(), baseType.flags(), ((ClassType)baseType).m_facets)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override abstract Type @base();

    public override List mixins()
    {
      return @base().mixins();
    }

    public override abstract string signature();

    public override bool isGenericInstance() { return true; }

    public override bool @is(Type type)
    {
      if (type == this || type == @base()) return true;
      return @base().@is(type);
    }

    public override Map @params()
    {
      if (m_params == null) m_params = makeParams();
      return m_params;
    }

    internal abstract Map makeParams();

  //////////////////////////////////////////////////////////////////////////
  // Reflect
  //////////////////////////////////////////////////////////////////////////

    /**
     * On reflection, we parameterize the master's methods.
     */
    protected override void doReflect()
    {
      // ensure master type is reflected
      Type master = @base();
      master.reflect();
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
          m_fields.add(slot);
        }
        m_slots.add(slot);
        m_slotsByName[slot.m_name] = slot;
      }

      // TODO - java code doesn't do this - but don't see anywhere
      // else where it gets set to something, so do it for now to
      // make things work
      if (m_facets == null) m_facets = Facets.empty();
    }

    /**
     * Parameterize the specified method (if reuse if generic
     * parameterization isn't necessary).
     */
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
        if (p.m_of.isGenericParameter())
        {
          pars.add(new Param(p.m_name, parameterize(p.m_of), p.m_mask));
        }
        else
        {
          pars.add(p);
        }
      }

      return new Method(this, m.m_name, m.m_flags, m.m_facets, m.m_lineNum, ret, m.m_inheritedReturns, pars, m);
    }

    /**
     * Parameterize t, where t is a generic parameter type such as V.
     */
    internal Type parameterize(Type t)
    {
      if (t is ListType)
        return parameterizeListType((ListType)t);
      else if (t is FuncType)
        return parameterizeFuncType((FuncType)t);
      else
        return doParameterize(t);
    }

    /**
     * Recursively parameterize the a generic list type.
     */
    internal Type parameterizeListType(ListType t)
    {
      return doParameterize(t.m_v).toListOf();
    }

    /**
     * Recursively parameterize the pars of a method type.
     */
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

    /**
     * Parameterize t, where t is a generic parameter type such as V.
     */
    protected abstract Type doParameterize(Type t);

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Map m_params;
  }

}