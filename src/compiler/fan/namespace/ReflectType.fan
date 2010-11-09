//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Jun 06  Brian Frank  Creation
//

**
** ReflectType is the implementation of CType for a type imported
** from a precompiled pod (as opposed to a TypeDef within the compilation
** units being compiled).
**
class ReflectType : CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with loaded Type.
  **
  new make(ReflectNamespace ns, Type t)
  {
    this.pod     = ns.importPod(t.pod)
    this.t       = t
    this.base    = ns.importType(t.base)
    this.mixins  = ns.importTypes(t.mixins)
    this.isVal   = t.isVal
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override ReflectNamespace ns() { return pod.ns }
  override Str name()      { return t.name }
  override Str qname()     { return t.qname }
  override Str signature() { return t.signature }
  override Int flags()     { return (Int)t->flags }

  override readonly Bool isVal

  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric() { return t.isGeneric }
  override Bool isParameterized() { return !t.params.isEmpty }
  override Bool isGenericParameter() { return pod === ns.sysPod && name.size == 1 }

  override once CType toListOf() { return ListType(this) }

  override CFacet? facet(Str qname)
  {
    try
      return ReflectFacet.map(ns, t.facet(Type.find(qname), false))
    catch (Err e)
      e.trace
    return null
  }

  override Str:CSlot slots()
  {
    if (!slotsLoaded)
    {
      slotsLoaded = true
      if (!isGenericParameter)
      {
        t.slots.each |Slot s|
        {
          if (slotMap[s.name] == null)
            slotMap[s.name] = ns.importSlot(s)
        }
      }
    }
    return slotMap
  }

  override once COperators operators() { COperators(this) }

  override CSlot? slot(Str name)
  {
    cs := slotMap[name]
    if (cs == null)
    {
      s := t.slot(name, false)
      if (s != null)
        slotMap[name] = cs = ns.importSlot(s)
    }
    return cs
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly Type t
  override readonly ReflectPod pod
  override readonly CType? base
  override readonly CType[] mixins
  private Str:CSlot slotMap := Str:CSlot[:]
  private Bool slotsLoaded := false

}