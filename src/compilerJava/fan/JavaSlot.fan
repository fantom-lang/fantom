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
  override Str name
  override once Str qname() { return parent.qname + "." + name }
  override Int flags

  // for native Java
  Void setName(Str n) { name = n }
  Void setFlags(Int f) { flags = f }

  ** linked list of overloaded methods (first one
  ** may be field or method)
  JavaMethod? next
}

**************************************************************************
** JavaField
**************************************************************************

class JavaField : JavaSlot, CField
{
  override CType parent
  override CType fieldType
  override CMethod? getter
  override CMethod? setter

  override Str signature() { return "$fieldType $name" }
  override CType inheritedReturnType() { return fieldType }

  override Bool isForeign() { return true }

  // for native Java
  Void setParent(JavaType p) { parent = p }
  Void setFieldType(Obj t) { fieldType = ns.resolveType(t) }
  JavaMethod? getNext() { return next }
  Void setNext(JavaMethod? m) { next = m }

}

**************************************************************************
** JavaMethod
**************************************************************************

class JavaMethod : JavaSlot, CMethod
{
  override CType parent
  override CType returnType
  override CParam[] params
  override Bool isGeneric

  override Str signature() { return "$returnType $name(" + params.join(",") + ")" }
  override CType inheritedReturnType() { return returnType }

  override Bool isForeign() { return true }

  // for native Java
  Void setParent(JavaType p) { parent = p }
  Void setReturnType(JavaType t) { returnType = t }
  Void setReturnTypeSig(Str t) { returnType = ns.resolveType(t) }
  Void setParamTypes(Obj[] types)
  {
    params = types.map(JavaParam[,]) |Obj t, Int i->CParam|
    {
      return JavaParam("p$i", ns.resolveType(t))
    }
  }
  JavaMethod? getNext() { return next }
  Void setNext(JavaMethod? m) { next = m }
}

**************************************************************************
** JavaParam
**************************************************************************

class JavaParam : CParam
{
  new make(Str n, CType t) { name = n; paramType = t }
  override Str name
  override Bool hasDefault
  override CType paramType
  override Str toStr() { return "$paramType $name" }
}