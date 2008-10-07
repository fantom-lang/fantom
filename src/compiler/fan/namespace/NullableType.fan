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

  override Bool isNullable() { return true }
  override CType toNullable() { return this }

  override Bool isGeneric() { return false }
  override Bool isParameterized() { return false }
  override Bool isGenericParameter() { return false }

  override once CType toListOf() { return root.toListOf.toNullable }

  override CType base() { return root.base }
  override CType[] mixins() { return root.mixins }

  override Str:CSlot slots() { return root.slots }

  override Str toStr() { return signature }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly CType root
}