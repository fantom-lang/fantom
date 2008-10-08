//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 06  Brian Frank  Creation
//

**
** TypeRef models a type reference such as an extends clause or a
** method parameter.  Really it is just an AST node wrapper for a
** CType that let's us keep track of the source code Location.
**
class TypeRef : Node, CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Location location, CType t)
    : super(location)
  {
    this.t = t
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return t.ns }
  override CPod pod()      { return t.pod }
  override Str name()      { return t.name }
  override Str qname()     { return t.qname }
  override Str signature() { return t.signature }
  override CType deref()   { return t }
  override Int flags()     { return t.flags }

  override CType base() { return t.base }
  override CType[] mixins() { return t.mixins }
  override Bool fits(CType that) { return t.fits(that) }

  override Bool isNullable() { return t.isNullable }
  override CType toNullable() { return t.toNullable }
  override CType toNonNullable() { return t.toNonNullable }

  override Bool isGeneric() { return t.isGeneric }
  override Bool isParameterized() { return t.isParameterized }
  override Bool isGenericParameter() { return t.isGenericParameter }
  override CType toListOf() { return t.toListOf }

  override Str:CSlot slots() { return t.slots }

  override Str toStr() { return signature }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Void print(AstWriter out)
  {
    out.w(t.toStr)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly CType t

}