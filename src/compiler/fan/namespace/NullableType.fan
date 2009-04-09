//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Oct 08  Brian Frank  Creation
//

**
** NullableType wraps another CType as nullable with trailing "?".
**
class NullableType : CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CType root)
  {
    if (root.isNullable) throw Err("Cannot wrap $root as NullableType")
    this.root = root
    this.signature = root.signature + "?"
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return root.ns }
  override CPod pod()      { return root.pod }
  override Str name()      { return root.name }
  override Str qname()     { return root.qname }
  override Int flags()     { return root.flags }
  override Str signature

  override Bool isValue() { return root.isValue }

  override Bool isNullable() { return true }
  override CType toNullable() { return this }
  override CType toNonNullable() { return root }

  override Bool isGeneric() { return root.isGeneric }
  override Bool isParameterized() { return root.isParameterized }
  override Bool isGenericParameter() { return root.isGenericParameter }

  override Bool isForeign()   { return root.isForeign }
  override Bool isSupported() { return root.isSupported }
  override CType inferredAs()
  {
    x := root.inferredAs
    if (x === root) return this
    return x.toNullable
  }

  override once CType toListOf() { return ListType(this) }

  override CType? base() { return root.base }
  override CType[] mixins() { return root.mixins }
  override Bool fits(CType t) { return root.fits(t) }

  override Str:CSlot slots() { return root.slots }

  override Bool isValid() { root.isValid }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly CType root
}