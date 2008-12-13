//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaSlot is the implementation of CSlot for a Java member.
**
abstract class JavaSlot : CSlot
{
  override CNamespace ns() { return parent.ns }
  override CType parent
  override Str name
  override once Str qname() { return parent.qname + "." + name }
  override Int flags

  ** linked list of overloaded methods (first one
  ** may be field or method)
  JavaMethod? next
}

**************************************************************************
** JavaField
**************************************************************************

**
** JavaField is the implementation of CField for a Java field.
**
class JavaField : JavaSlot, CField
{
  override CType fieldType
  override CMethod? getter
  override CMethod? setter

  override Str signature() { return "$fieldType $name" }
  override CType inheritedReturnType() { return fieldType }

  override Bool isForeign() { return true }
}

**************************************************************************
** JavaMethod
**************************************************************************

**
** JavaMethod is the implementation of CMethod for a Java method.
**
class JavaMethod : JavaSlot, CMethod
{
  override CType parent
  override CType returnType
  override CParam[] params
  override Bool isGeneric

  override Str signature() { return "$returnType $name(" + params.join(",") + ")" }
  override CType inheritedReturnType() { return returnType }

  override Bool isForeign() { return true }

  Void setParamTypes(CType[] types)
  {
    params = types.map(JavaParam[,]) |CType t, Int i->CParam|
    {
      return JavaParam("p$i", t)
    }
  }
}

**************************************************************************
** JavaParam
**************************************************************************

**
** JavaParam is the implementation of CParam for a Java method parameter.
**
class JavaParam : CParam
{
  new make(Str n, CType t) { name = n; paramType = t }
  override Str name
  override Bool hasDefault
  override CType paramType
  override Str toStr() { return "$paramType $name" }
}