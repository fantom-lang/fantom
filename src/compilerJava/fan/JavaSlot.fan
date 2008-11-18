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
}

**************************************************************************
** JavaField
**************************************************************************

class JavaField : JavaSlot, CField
{
  override JavaType parent
  override CType fieldType
  override CMethod? getter
  override CMethod? setter

  override Str signature() { return "$fieldType $name" }
  override CType inheritedReturnType() { return fieldType }

  // for native Java
  Void setParent(JavaType p) { parent = p }
  Void setFieldType(Obj t) { fieldType = ns.resolveType(t) }

  ** java.lang.reflect.Field
  Obj java
}

**************************************************************************
** JavaMethod
**************************************************************************

class JavaMethod : JavaSlot, CMethod
{
  override JavaType parent
  override CType returnType
  override CParam[] params
  override Bool isGeneric

  override Str signature() { return "$returnType $name(" + params.join(",") + ")" }
  override CType inheritedReturnType() { return returnType }

  // for native Java
  Void setParent(JavaType p) { parent = p }
  Void setReturnType(Str t) { returnType = ns.resolveType(t) }
  Void setParamTypes(Obj[] types)
  {
    params = types.map(JavaParam[,]) |Obj t, Int i->CParam|
    {
      return JavaParam { name="p$i"; paramType = ns.resolveType(t) }
    }
  }

  ** java.lang.reflect.Methods
  Obj[] java := Obj[,]
}

**************************************************************************
** JavaParam
**************************************************************************

class JavaParam : CParam
{
  override Str name
  override Bool hasDefault
  override CType paramType
  override Str toStr() { return "$paramType $name" }
}