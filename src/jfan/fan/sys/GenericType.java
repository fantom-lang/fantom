//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 06 (Fri 13th)  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.HashMap;
import fanx.fcode.*;
import fanx.emit.*;

/**
 * GenericType is the base class for ListType, MapType, and MethodType
 * which all support parameterization of the generic parameter types (such
 * as A-H, V, K).  Instances of GenericType are used to represent generic
 * instances (for example an instance of ListType is used to represent Str[]).
 */
public abstract class GenericType
  extends Type
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  GenericType(Type base) { this.base = base; }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Pod pod() { return base.pod(); }
  public final String name() { return base.name(); }
  public final String qname() { return base.qname(); }
  public abstract String signature();
  int flags() { return base.flags(); }

  public final Type base() { return base; }
  public final List mixins() { return base.mixins(); }
  public final List inheritance() { return base.inheritance(); }

  public final boolean isGenericInstance() { return true; }

  public boolean is(Type type)
  {
    if (type == this || type == base) return true;
    return base.is(type);
  }

  public final List fields()  { return reflect().fields.ro(); }
  public final List methods() { return reflect().methods.ro(); }
  public final List slots()   { return reflect().slots.ro(); }

  public final Slot slot(String name, boolean checked)
  {
    Slot slot = (Slot)reflect().slotsByName.get(name);
    if (slot != null) return slot;
    if (checked) throw UnknownSlotErr.make(this.qname() + "." + name).val;
    return null;
  }

  public Map params()
  {
    if (params == null) params = makeParams();
    return params;
  }

  abstract Map makeParams();

  public Map facets(Boolean inherited) { return base.facets(inherited); }
  public Object facet(String name, Object def, Boolean inherited) { return base.facet(name, def, inherited); }

  public String doc() { return base.doc(); }

  public final boolean javaRepr() { return false; }

//////////////////////////////////////////////////////////////////////////
// Reflect
//////////////////////////////////////////////////////////////////////////

  /**
   * On reflection, we parameterize the master's methods.
   */
  protected final synchronized GenericType reflect()
  {
    if (slotsByName != null) return this;
    doReflect();
    return this;
  }

  private void doReflect()
  {
    // ensure master type is reflected
    Type master = base;
    master.finish();
    List masterSlots = master.slots();

    // allocate slot data structures
    fields = new List(Sys.FieldType, master.fields().sz());
    methods = new List(Sys.MethodType, master.methods().sz());
    slots = new List(Sys.SlotType, masterSlots.sz());
    slotsByName = new HashMap(masterSlots.sz()*3);

    // parameterize master's slots
    for (int i=0; i<masterSlots.sz(); ++i)
    {
      Slot slot = (Slot)masterSlots.get(i);
      if (slot instanceof Method)
      {
        slot = parameterize((Method)slot);
        methods.add(slot);
      }
      else
      {
        fields.add(slot);
      }
      slots.add(slot);
      slotsByName.put(slot.name, slot);
    }
  }

  /**
   * Parameterize the specified method (if reuse if generic
   * parameterization isn't necessary).
   */
  Method parameterize(Method m)
  {
    // if not generic, short circuit and reuse original
    if (!m.isGenericMethod()) return m;

    // new signature
    Func func = m.func;
    Type ret;
    List params = new List(Sys.ParamType, m.params.sz());

    // parameterize return type
    if (func.returns.isGenericParameter())
      ret = parameterize(func.returns);
    else
      ret = func.returns;

    // narrow params (or just reuse if not parameterized)
    for (int i=0; i<m.params.sz(); ++i)
    {
      Param p = (Param)m.params.get(i);
      if (p.of.isGenericParameter())
      {
        params.add(new Param(p.name, parameterize(p.of), p.mask));
      }
      else
      {
        params.add(p);
      }
    }

    Method pm = new Method(this, m.name, m.flags, m.facets, m.lineNum, ret, m.inheritedReturns, params, m);
    pm.reflect = m.reflect;
    return pm;
  }

  /**
   * Parameterize t, where t is a generic parameter type such as V.
   */
  final Type parameterize(Type t)
  {
    if (t instanceof ListType)
      return parameterizeListType((ListType)t);
    else if (t instanceof FuncType)
      return parameterizeFuncType((FuncType)t);
    else
      return doParameterize(t);
  }

  /**
   * Recursively parameterize the a generic list type.
   */
  final Type parameterizeListType(ListType t)
  {
    return doParameterize(t.v).toListOf();
  }

  /**
   * Recursively parameterize the params of a method type.
   */
  final FuncType parameterizeFuncType(FuncType t)
  {
    Type[] params = new Type[t.params.length];
    for (int i=0; i<params.length; ++i)
    {
      Type param = t.params[i];
      if (param.isGenericParameter()) param = doParameterize(param);
      params[i] = param;
    }

    Type ret = t.ret;
    if (ret.isGenericParameter()) ret = doParameterize(ret);

    return new FuncType(params, ret);
  }

  /**
   * Parameterize t, where t is a generic parameter type such as V.
   */
  protected abstract Type doParameterize(Type t);

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // available at construction time
  private final Type base;

  // lazily created by params()
  private Map params;

   // available when reflected
  private List fields;
  private List methods;
  private List slots;
  private HashMap slotsByName;  // String:Slot
}