//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using compiler

**
** Base class for Java transpiler print
**
internal class JavaPrinter : CodePrinter
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  new makeTop(OutStream out)
  {
    this.mRef = JavaPrinterState(out)
  }

  new make(JavaPrinter parent)
  {
    this.mRef = parent.mRef
  }

//////////////////////////////////////////////////////////////////////////
// Choke point for qualified names
//////////////////////////////////////////////////////////////////////////

  This qnOpUtil() { w("OpUtil") }

  This qnFanObj() { w("FanObj") }

  This qnFanVal(CType t)
  {
    // decimal rare, always use full qname
    if (t.isDecimal) return w("fan.sys.FanDecimal")
    // FanStr, FanInt, FanBool, etc
    return w("Fan").w(t.name)
  }

  This qnList() { w("List") }

  This qnMap() { w("Map") }

  This qnType() { w("Type") }

  This qnFunc() { w("Func") }

  This qnSys() { w("Sys") }

//////////////////////////////////////////////////////////////////////////
// Identifier Handling
//////////////////////////////////////////////////////////////////////////

  This typeName(CType t)
  {
    w(JavaUtil.typeName(t))
  }

  This fieldName(CField x)
  {
    w(JavaUtil.fieldName(x))
  }

  This methodName(CMethod x)
  {
    w(JavaUtil.methodName(x))
  }

  This varName(Str x)
  {
    w(JavaUtil.varName(x))
  }

//////////////////////////////////////////////////////////////////////////
// Type Signatures
//////////////////////////////////////////////////////////////////////////

  This typeSig(CType t, Bool parameterize := true)
  {
    // speical handling for system types
    if (t.pod.name == "sys")
    {
      base := t.toNonNullable
      if (t.isVoid)      return w("void")
      if (t.isObj)       return w("Object")
      if (t.isStr)       return w("String")
      if (t.isBool)      return t.isNullable ? w("Boolean") : w("boolean")
      if (t.isInt)       return t.isNullable ? w("Long") : w("long")
      if (t.isFloat)     return t.isNullable ? w("Double") : w("double")
      if (t.isDecimal)   return w("java.math.BigDecimal")
      if (t.isNum)       return w("java.lang.Number")
      if (t.isType)      return qnType
      if (t.isFunc)      return qnFunc
      if (t.isThis)      return typeSig(curType)
      if (base is ListType) return listSig(base, parameterize)
      if (base is MapType)  return mapSig(base, parameterize)
      if (base.isGenericParameter)
      {
        if (t.name == "L") return qnList.w("<V>")
        if (t.name == "M") return qnMap.w("<K,V>")
        return w(t.name)
      }
    }

    // assume synthetics are my own inner classes
    if (t.isSynthetic)
    {
      if (JavaUtil.isSyntheticWrapper(t))
      {
        // keep track of synthetic wrappers used by parent type
        name := JavaUtil.syntheticWrapperName(t)
        wrappers[name] = t
        return w(name)
      }
      else
      {
        // closure synthetic
        name := JavaUtil.syntheticClosureName(t)
        return w(name)
      }
    }

    // qname
    return w("fan.").w(t.pod.name).w(".").typeName(t)
  }

  This listSig(ListType t, Bool parameterize)
  {
    qnList
    if (parameterizeSig(parameterize))
      w("<").typeSigNullable(t.v).w(">")
    return this
  }

  This mapSig(MapType t, Bool parameterize)
  {
    qnMap
    if (parameterizeSig(parameterize))
      w("<").typeSigNullable(t.k).w(",").typeSigNullable(t.v).w(">")
    return this
  }

  Bool parameterizeSig(Bool flag)
  {
    if (!flag) return false
    if (closure != null && curMethod?.name == "callList") return false
    return true
  }

  This typeSigNullable(CType t, Bool parameterize := true)
  {
    if (t.isVal)
    {
      if (t.isBool)    return w("Boolean")
      if (t.isInt)     return w("Long")
      if (t.isFloat)   return w("Double")
    }
    return typeSig(t, parameterize)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  This str(Obj x)
  {
    w(x.toStr.toCode.replace("\\\$", "\$"))
  }

  This eos() { w(";").nl }

  Void warn(Str msg, Loc loc)
  {
    echo("WARN: $msg [$loc.toLocStr]")
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  override JavaPrinterState m() { mRef }
  private JavaPrinterState mRef

  TypeDef? curType() { m.curType }
  MethodDef? curMethod() { m.curMethod }
  TypeDef? closure() { m.closure }
  Str:TypeDef wrappers() { m.wrappers }
  Str? selfVar() { m.selfVar }
}

**************************************************************************
** JavaPrinterState
**************************************************************************

class JavaPrinterState : CodePrinterState
{
  new make(OutStream out) : super(out) {}

  TypeDef? curType
  Str:TypeDef wrappers := [:]
  MethodDef? curMethod
  TypeDef? closure
  Str? selfVar
}

