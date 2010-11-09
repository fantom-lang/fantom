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

  override CNamespace ns() { root.ns }
  override CPod pod()      { root.pod }
  override Str name()      { root.name }
  override Str qname()     { root.qname }
  override Int flags()     { root.flags }
  override Str signature

  override Bool isVal() { root.isVal }

  override CFacet? facet(Str qname) { return root.facet(qname) }

  override Bool isNullable() { true }
  override CType toNullable() { this }
  override CType toNonNullable() { root }

  override Bool isGeneric() { root.isGeneric }
  override Bool isParameterized() { root.isParameterized }
  override Bool isGenericParameter() { root.isGenericParameter }
  override CType parameterizeThis(CType thisType) { root.parameterizeThis(thisType).toNullable }

  override Bool isForeign()   { root.isForeign }
  override Bool isSupported() { root.isSupported }
  override CType inferredAs()
  {
    x := root.inferredAs
    if (x === root) return this
    return x.toNullable
  }

  override once CType toListOf() { ListType(this) }

  override CType? base() { root.base }
  override CType[] mixins() { root.mixins }
  override Bool fits(CType t) { root.fits(t) }

  override Str:CSlot slots() { return root.slots }
  override COperators operators() { return root.operators }

  override Bool isValid() { root.isValid }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly CType root
}