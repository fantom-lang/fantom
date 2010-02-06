//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 06  Brian Frank  Creation
//

**
** ReflectSlot is the implementation of CSlot for a slot imported
** from a precompiled pod (as opposed to a SlotDef within the
** compilation units being compiled).
**
abstract class ReflectSlot : CSlot
{
  new make(Slot slot)
  {
    this.flags = (Int)slot->flags // undocumented trap
  }

  override abstract ReflectNamespace ns()  // covariant redefinition
  override abstract ReflectType parent()   // covariant redefinition
  override Str name()      { return slot.name }
  override Str qname()     { return slot.qname }
  override Str signature() { return slot.signature }
  override readonly Int flags
  abstract Slot slot()

  override CFacet? facet(Str qname)
  {
    try
      return ReflectFacet.map(ns, slot.facet(Type.find(qname), false))
    catch (Err e)
      e.trace
    return null
  }
}

**************************************************************************
** ReflectField
**************************************************************************

class ReflectField : ReflectSlot, CField
{
  new make(ReflectType parent, Field f)
    : super(f)
  {
    this.parent = parent
    this.f = f
    this.fieldType = ns.importType(f.type)
    get := (Method?)f->getter; if (get != null) this.getter = ns.importMethod(get)
    set := (Method?)f->setter; if (set != null) this.setter = ns.importMethod(set)
  }

  override ReflectNamespace ns() { return parent.ns }
  override ReflectType parent

  override Slot slot() { return f }

  override CType inheritedReturnType()
  {
    if (!isOverride || getter == null) return fieldType
    else return getter.inheritedReturnType
  }

  override readonly CType fieldType
  override readonly CMethod? getter
  override readonly CMethod? setter
  readonly Field f
}

**************************************************************************
** ReflectMethod
**************************************************************************

class ReflectMethod : ReflectSlot, CMethod
{
  new make(ReflectType parent, Method m)
    : super(m)
  {
    this.parent = parent
    this.m = m
    this.returnType = ns.importType(m.returns)
    this.params = m.params.map |Param p->CParam| { ReflectParam(ns, p) }
    this.isGeneric = calcGeneric(this)
  }

  override ReflectNamespace ns() { return parent.ns }
  override ReflectType parent

  override Slot slot() { return m }

  override CType inheritedReturnType()
  {
    // use trap to access undocumented hook
    if (isOverride || returnType.isThis)
      return ns.importType((Type)m->inheritedReturnType)
    else
      return returnType
  }

  override readonly CType returnType
  override readonly CParam[] params
  override readonly Bool isGeneric
  readonly Method m
}

**************************************************************************
** ReflectParam
**************************************************************************

class ReflectParam : CParam
{
  new make(ReflectNamespace ns, Param p)
  {
    this.p = p
    this.paramType = ns.importType(p.type)
  }

  override Str name() { return p.name }
  override Bool hasDefault() { return p.hasDefault }

  override readonly CType paramType
  readonly Param p
}

**************************************************************************
** ReflectFacet
**************************************************************************

class ReflectFacet : CFacet
{
  static ReflectFacet? map(ReflectNamespace ns, Facet? f)
  {
    if (f == null) return null
    return make(f)
  }
  private new make(Facet f) { this.f = f }
  override Str qname() { f.typeof.qname }
  override Obj? get(Str name) { f.typeof.field(name, false)?.get(f) }
  override Str toStr() { f.toStr }
  Facet f
}