//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 06  Brian Frank  Creation
//

**
** CSlot is a "compiler slot" which is represents a Slot in the
** compiler.  CSlots unifies slots being compiled as SlotDefs
** with slots imported as ReflectSlot or FSlot.
**
mixin CSlot
{
  virtual CNamespace ns() { return parent.ns }
  abstract CType parent()
  abstract Str name()
  abstract Str qname()
  abstract Str signature()
  abstract Int flags()

  Bool isAbstract()  { return flags & FConst.Abstract  != 0 }
  Bool isAccessor()  { return flags & (FConst.Getter | FConst.Setter) != 0 }
  Bool isConst()     { return flags & FConst.Const     != 0 }
  Bool isCtor()      { return flags & FConst.Ctor      != 0 }
  Bool isEnum()      { return flags & FConst.Enum      != 0 }
  Bool isGetter()    { return flags & FConst.Getter    != 0 }
  Bool isInternal()  { return flags & FConst.Internal  != 0 }
  Bool isNative()    { return flags & FConst.Native    != 0 }
  Bool isOverride()  { return flags & FConst.Override  != 0 }
  Bool isPrivate()   { return flags & FConst.Private   != 0 }
  Bool isProtected() { return flags & FConst.Protected != 0 }
  Bool isPublic()    { return flags & FConst.Public    != 0 }
  Bool isSetter()    { return flags & FConst.Setter    != 0 }
  Bool isStatic()    { return flags & FConst.Static    != 0 }
  Bool isStorage()   { return flags & FConst.Storage   != 0 }
  Bool isSynthetic() { return flags & FConst.Synthetic != 0 }
  Bool isVirtual()   { return flags & FConst.Virtual   != 0 }
}

**************************************************************************
** CField
**************************************************************************

**
** CField is a "compiler field" which is represents a Field in the
** compiler.  CFields unify methods being compiled as FieldDefs
** with methods imported as ReflectField or FField.
**
mixin CField : CSlot
{
  abstract CType fieldType()
  abstract CMethod getter()
  abstract CMethod setter()

  **
  ** Original return type from inherited method if a covariant override.
  **
  abstract CType inheritedReturnType()

  **
  ** Does this field covariantly override a method?
  **
  Bool isCovariant() { return isOverride && fieldType != inheritedReturnType }

  **
  ** Is this field typed with a generic parameter.
  **
  Bool isGeneric() { return fieldType.isGenericParameter }

  **
  ** Is this field the parameterization of a generic field,
  ** with the generic type replaced with a real type.
  **
  virtual Bool isParameterized() { return false }
}

**************************************************************************
** CMethod
**************************************************************************

**
** CMethod is a "compiler method" which is represents a Method in the
** compiler.  CMethods unify methods being compiled as MethodDefs
** with methods imported as ReflectMethod or FMethod.
**
mixin CMethod : CSlot
{
  **
  ** Return type
  **
  abstract CType returnType()

  **
  ** Parameter signatures
  **
  abstract CParam[] params()

  **
  ** Original return type from inherited method if a covariant override.
  **
  abstract CType inheritedReturnType()

  **
  ** Does this method have a covariant return type (we
  ** don't count This returns as covariant)
  **
  Bool isCovariant() { return isOverride && !returnType.isThis && returnType != inheritedReturnType }

  **
  ** Does this method contains generic parameters in its signature.
  **
  virtual Bool isGeneric() { return false }

  **
  ** Is this method the parameterization of a generic method,
  ** with all the generic parameters filled in with real types.
  **
  virtual Bool isParameterized() { return false }

  **
  ** If isParameterized is true, then return the generic
  ** method which this method parameterizes, otherwise null
  **
  virtual CMethod generic() { return null }

  static Bool calcGeneric(CMethod m)
  {
    if (!m.parent.isGeneric) return false
    isGeneric := m.returnType.isGenericParameter
    m.params.each |CParam p| { isGeneric = isGeneric || p.paramType.isGenericParameter }
    return isGeneric
  }

  **
  ** Return a string with the name and parameters.
  **
  Str nameAndParamTypesToStr()
  {
    return name + "(" +
      params.join(", ", |CParam p->Str| { return p.paramType.signature }) +
      ")"
  }

  **
  ** Return if this method has the exact same parameters as
  ** the specified method.
  **
  Bool hasSameParams(CMethod that)
  {
    a := params
    b := that.params

    if (a.size != b.size) return false
    for (i:=0; i<a.size; ++i)
      if (a[i].paramType != b[i].paramType) return false

    return true
  }

}

**************************************************************************
** CParam
**************************************************************************

**
** CParam models a MethodParam in the compiler.  CParams unify the params
** being compiled (ParamDef) and parameters imported (ReflectParam, FMethodVar)
**
mixin CParam
{
  abstract Str name()
  abstract CType paramType()
  abstract Bool hasDefault()
}
