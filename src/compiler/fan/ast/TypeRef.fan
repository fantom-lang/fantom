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
  override Bool isForeign() { return t.isForeign }
  override Int flags()     { return t.flags }

  override CType? base() { return t.base }
  override CType[] mixins() { return t.mixins }
  override Bool fits(CType that) { return t.fits(that) }

  override Bool isValid() { t.isValid }

  override Bool isValue() { return t.isValue }

  override Bool isNullable() { return t.isNullable }
  override CType toNullable() { return t.toNullable }
  override CType toNonNullable() { return t.toNonNullable }

  override CType inferredAs() { return t.inferredAs }

  override Bool isGeneric() { return t.isGeneric }
  override Bool isParameterized() { return t.isParameterized }
  override Bool isGenericParameter() { return t.isGenericParameter }
  override CType parameterizeThis(CType thisType) { t.parameterizeThis(thisType) }
  override CType toListOf() { return t.toListOf }

  override CSlot? slot(Str name) { return t.slot(name) }
  override CField? field(Str name) { return t.field(name) }
  override CMethod? method(Str name) { return t.method(name) }
  override Str:CSlot slots() { return t.slots }

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