//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//   21 Jul 06  Brian Frank  Ported from Java to Fan
//

**
** FieldDef models a field definition
**
public class FieldDef : SlotDef, CField
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Location location, TypeDef parent)
     : super(location, parent)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  Bool hasGet() { return get != null && !get.isSynthetic }
  Bool hasSet() { return set != null && !set.isSynthetic }

  FieldExpr makeAccessorExpr(Location loc, Bool useAccessor)
  {
    Expr target
    if (isStatic)
      target = StaticTargetExpr.make(loc, parent)
    else
      target = ThisExpr.make(loc)

    return FieldExpr.make(loc, target, this, useAccessor)
  }

//////////////////////////////////////////////////////////////////////////
// CField
//////////////////////////////////////////////////////////////////////////

  override Str signature() { return qname }
  override CMethod getter() { return get }
  override CMethod setter() { return set }

  override CType inheritedReturnType()
  {
    if (inheritedRet != null)
      return inheritedRet
    else
      return fieldType
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  override Void walk(Visitor v, VisitDepth depth)
  {
    v.enterFieldDef(this)
    walkFacets(v, depth)
    if (depth >= VisitDepth.expr && init != null)
      init = init.walk(v)
    v.visitFieldDef(this)
    v.exitFieldDef(this)
  }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  override Str:Str docMeta()
  {
    if (initDoc == null) return null
    return ["def": initDoc.toDocStr]
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Str toStr()
  {
    return "$fieldType $name"
  }

  override Void print(AstWriter out)
  {
    printFacets(out)
    out.flags(flags)
    if (fieldType != null) out.w(fieldType).w(" ")
    out.w(name)
    if (init != null) { out.w(" := "); init.print(out) }
    out.nl.nl
   }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override CType fieldType  // field type (null if inferred from init)
  Field field               // resolved finalized field
  Expr init                 // init expression or null
  Expr initDoc              // original init expression for documentation only
  MethodDef get             // getter MethodDef
  MethodDef set             // setter MethodDef
  CField concreteBase       // if I override a concrete virtual field
  CType inheritedRet        // if covariant override of method

}