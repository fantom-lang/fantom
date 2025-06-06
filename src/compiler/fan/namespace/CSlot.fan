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
mixin CSlot : CNode
{
  override CNamespace ns() { parent.ns }
  abstract CType parent()
  abstract Str name()
  abstract Str qname()
  abstract Str signature()
  abstract Int flags()

  override final Str toStr() { signature }

  Bool isAbstract()  { flags.and(FConst.Abstract)  != 0 }
  Bool isAccessor()  { flags.and(FConst.Getter.or(FConst.Setter)) != 0 }
  Bool isConst()     { flags.and(FConst.Const)     != 0 }
  Bool isCtor()      { flags.and(FConst.Ctor)      != 0 }
  Bool isEnum()      { flags.and(FConst.Enum)      != 0 }
  Bool isGetter()    { flags.and(FConst.Getter)    != 0 }
  Bool isInternal()  { flags.and(FConst.Internal)  != 0 }
  Bool isNative()    { flags.and(FConst.Native)    != 0 }
  Bool isOverride()  { flags.and(FConst.Override)  != 0 }
  Bool isPrivate()   { flags.and(FConst.Private)   != 0 }
  Bool isProtected() { flags.and(FConst.Protected) != 0 }
  Bool isPublic()    { flags.and(FConst.Public)    != 0 }
  Bool isSetter()    { flags.and(FConst.Setter)    != 0 }
  Bool isStatic()    { flags.and(FConst.Static)    != 0 }
  Bool isStorage()   { flags.and(FConst.Storage)   != 0 }
  Bool isSynthetic() { flags.and(FConst.Synthetic) != 0 }
  Bool isVirtual()   { flags.and(FConst.Virtual)   != 0 }
  Bool isOnce()      { flags.and(FConst.Once)      != 0 }

  Bool isInstanceCtor() { isCtor && !isStatic }
  Bool isStaticCtor() { isCtor && isStatic }

  **
  ** If this a foreign function interface slot.  A FFI slot is one
  ** declared in another language.  See `usesForeign` to check if the
  ** slot uses any FFI types in its signature.
  **
  virtual Bool isForeign() { false }

  **
  ** Return if this slot is foreign or uses any foreign types in its signature.
  **
  Bool usesForeign() { usesBridge != null }

  **
  ** If this a foreign function return the bridge.  See `usesForeign` to
  ** check if the slot uses any FFI types in its signature.
  **
  virtual CBridge? bridge() { parent.pod.bridge }

  **
  ** Return the bridge if this slot is foreign or uses any foreign
  ** types in its signature.
  **
  abstract CBridge? usesBridge()

  **
  ** Return if this slot is visible to the given type
  **
  Bool isVisibleTo(CType curType)
  {
    if (parent == curType) return true
    if (isPrivate) return false
    if (isInternal) return parent.pod == curType.pod
    if (isProtected) return parent.pod == curType.pod || curType.fits(parent)
    return true
  }

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
  @Deprecated CType fieldType() { type }

  abstract CType type()
  abstract CMethod? getter()
  abstract CMethod? setter()

  **
  ** Original return type from inherited method if a covariant override.
  **
  abstract CType inheritedReturns()

  **
  ** Does this field covariantly override a method?
  **
  Bool isCovariant() { isOverride && type != inheritedReturns }

  **
  ** Is this field typed with a generic parameter.
  **
  Bool isGeneric() { type.isGenericParameter }

  **
  ** Is this field the parameterization of a generic field,
  ** with the generic type replaced with a real type.
  **
  virtual Bool isParameterized() { false }

  **
  ** Return the bridge if this slot is foreign or uses any foreign
  ** types in its signature.
  **
  override CBridge? usesBridge()
  {
    if (bridge != null) return bridge
    return type.bridge
  }
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
  abstract CType returns()

  @Deprecated CType returnType() { returns }

  **
  ** Parameter signatures
  **
  abstract CParam[] params()

  **
  ** Original return type from inherited method if a covariant override.
  **
  abstract CType inheritedReturns()

  @Deprecated  CType inheritedReturnType() { inheritedReturns }

  **
  ** Does this method have a covariant return type (we
  ** don't count This returns as covariant)
  **
  Bool isCovariant() { isOverride && !returns.isThis && returns != inheritedReturns }

  **
  ** Return the bridge if this slot is foreign or uses any foreign
  ** types in its signature.
  **
  override CBridge? usesBridge()
  {
    if (bridge != null) return bridge
    if (returns.bridge != null) return returns.bridge
    return params.eachWhile |CParam p->CBridge?| { p.type.bridge }
  }

  **
  ** Does this method contains generic parameters in its signature.
  **
  virtual Bool isGeneric() { false }

  **
  ** Is this method the parameterization of a generic method,
  ** with all the generic parameters filled in with real types.
  **
  virtual Bool isParameterized() { false }

  **
  ** If isParameterized is true, then return the generic
  ** method which this method parameterizes, otherwise null
  **
  virtual CMethod? generic() { null }

  static Bool calcGeneric(CMethod m)
  {
    if (!m.parent.isGeneric) return false
    isGeneric := m.returns.isGenericParameter
    m.params.each |CParam p| { isGeneric = isGeneric || p.type.isGenericParameter }
    return isGeneric
  }

  **
  ** Return a string with the name and parameters.
  **
  Str nameAndParamTypesToStr()
  {
    return name + "(" +
      params.join(", ", |CParam p->Str| { p.type.inferredAs.signature }) +
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
      if (a[i].type != b[i].type) return false

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
  abstract CType type()
  abstract Bool hasDefault()
  @Deprecated CType paramType() { type }
}

**************************************************************************
** CFacet
**************************************************************************

**
** CFacet models a facet definition in a CType or CSlot
**
mixin CFacet
{
  ** Qualified name of facet type
  abstract Str qname()

  ** Get the value of the given facet field or null if undefined.
  abstract Obj? get(Str name)
}

**
** Simple implementation for a marker facet
**
const class MarkerFacet : CFacet
{
  new make(Str qname) { this.qname = qname }
  override const Str qname
  override Obj? get(Str name) { null }

}

