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

  override CNamespace ns() { t.ns }
  override CPod pod()      { t.pod }
  override Str name()      { t.name }
  override Str qname()     { t.qname }
  override Str signature() { t.signature }
  override CType deref()   { t }
  override Bool isForeign() { t.isForeign }
  override Obj? facet(Str qname, Obj? def) { t.facet(qname, def) }
  override Int flags()     { t.flags }

  override CType? base() { t.base }
  override CType[] mixins() { t.mixins }
  override Bool fits(CType that) { t.fits(that) }

  override Bool isValid() { t.isValid }

  override Bool isVal() { t.isVal }

  override Bool isNullable() { t.isNullable }
  override CType toNullable() { t.toNullable }
  override CType toNonNullable() { t.toNonNullable }

  override CType inferredAs() { t.inferredAs }

  override Bool isGeneric() { t.isGeneric }
  override Bool isParameterized() { t.isParameterized }
  override Bool isGenericParameter() { t.isGenericParameter }
  override CType parameterizeThis(CType thisType) { t.parameterizeThis(thisType) }
  override CType toListOf() { t.toListOf }

  override CSlot? slot(Str name) { t.slot(name) }
  override CField? field(Str name) { t.field(name) }
  override CMethod? method(Str name) { t.method(name) }
  override Str:CSlot slots() { t.slots }

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