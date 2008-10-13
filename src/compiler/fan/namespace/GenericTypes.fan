//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jul 06  Brian Frank  Creation
//

**
** GenericType models a parameterized generic type: List, Map, or Func
**
abstract class GenericType : CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CType base)
  {
    this.base = base
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return base.ns }
  override CPod pod()      { return ns.sysPod }
  override Str name()      { return base.name }
  override Str qname()     { return base.qname }
  override Int flags()  { return 0 }

  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric() { return false }
  override Bool isParameterized() { return true }

  override once CType toListOf() { return ListType(this) }

  override CType[] mixins() { return CType[,] }

  override Str:CSlot slots
  {
    get
    {
      if (@slots == null) @slots = parameterizeSlots()
      return @slots
    }
  }

  override Str toStr() { return signature() }

//////////////////////////////////////////////////////////////////////////
// Parameterize
//////////////////////////////////////////////////////////////////////////

  private Str:CSlot parameterizeSlots()
  {
    s := Str:CSlot[:]
    base.slots.map(s) |CSlot slot->Obj| { return parameterizeSlot(slot) }
    return s
  }

  private CSlot parameterizeSlot(CSlot slot)
  {
    if (slot is CMethod)
    {
      CMethod m := slot
      if (!m.isGeneric) return slot
      return ParameterizedMethod.make(this, m)
    }
    else
    {
      f := (CField)slot
      if (!f.fieldType.isGenericParameter) return slot
      return ParameterizedField.make(this, f)
    }
  }

  internal CType parameterize(CType t)
  {
    if (!t.isGenericParameter) return t
    nullable := t.isNullable
    nn := t.toNonNullable
    if (nn is ListType)
    {
      t = parameterizeListType(nn)
    }
    else if (nn is FuncType)
    {
      t = parameterizeFuncType(nn)
    }
    else
    {
      if (nn.name.size != 1) throw CompilerErr.make("Cannot parameterize $t.qname", null)
      t = doParameterize(nn.name[0])
    }
    return nullable ? t.toNullable : t
  }

  private CType parameterizeListType(ListType t)
  {
    return parameterize(t.v).toListOf
  }

  private CType parameterizeFuncType(FuncType t)
  {
    params := (CType[])t.params.map(CType[,]) |CType p->CType| { return parameterize(p) }
    ret := parameterize(t.ret)
    return FuncType.make(params, t.names, ret)
  }

  abstract CType doParameterize(Int ch)

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly CType base
  private ListType listOf
}

**************************************************************************
** ListType
**************************************************************************

**
** ListType models a parameterized List type.
**
class ListType : GenericType
{
  new make(CType v)
    : super(v.ns.listType)
  {
    this.v = v
    this.signature = "${v.signature}[]"
  }

  override Bool isGenericParameter()
  {
    return v.isGenericParameter
  }

  override Bool fits(CType t)
  {
    t = t.toNonNullable
    if (this == t) return true
    if (t.signature == "sys::List") return true
    if (t.isObj) return true
    if (t.name.size == 1 && t.pod.name == "sys") return true

    that := t.deref as ListType
    if (that == null) return false

    return v.fits(that.v)
  }

  override CType doParameterize(Int ch)
  {
    switch (ch)
    {
      case 'V': return v
      case 'L': return this
      default:  throw Err.make(ch.toChar)
    }
  }

  readonly CType v         // value type
  override readonly Str signature   // v[]

}

**************************************************************************
** MapType
**************************************************************************

**
** MapType models a parameterized Map type.
**
class MapType : GenericType
{
  new make(CType k, CType v)
    : super(k.ns.mapType)
  {
    this.k = k
    this.v = v
    this.signature = "[${k.signature}:${v.signature}]"
  }

  override Bool isGenericParameter()
  {
    return k.isGenericParameter || v.isGenericParameter
  }

  override Bool fits(CType t)
  {
    t = t.toNonNullable
    if (this == t) return true
    if (t.signature == "sys::Map") return true
    if (t.isObj) return true
    if (t.name.size == 1 && t.pod.name == "sys") return true

    that := t.deref as MapType
    if (that == null) return false

    return k.fits(that.k) && v.fits(that.v)
  }

  override CType doParameterize(Int ch)
  {
    switch (ch)
    {
      case 'K': return k
      case 'V': return v
      case 'M': return this
      default:  throw Err.make(ch.toChar)
    }
  }

  readonly CType k         // keytype
  readonly CType v         // value type
  override readonly Str signature   // [k:v]

}

**************************************************************************
** FuncType
**************************************************************************

**
** FuncType models a parameterized Func type.
**
class FuncType : GenericType
{
  new make(CType[] params, Str[] names, CType ret)
    : super(ret.ns.funcType)
  {
    this.params = params
    this.names  = names
    this.ret    = ret
    this.isGenericParameter = ret.isGenericParameter

    s := StrBuf.make.add("|")
    params.each |CType p, Int i|
    {
      isGenericParameter |= p.isGenericParameter
      if (i > 0) s.add(","); s.add(p.signature)
    }
    s.add("->").add(ret.signature).add("|")
    this.signature = s.toStr
  }

  override Bool fits(CType t)
  {
    t = t.toNonNullable
    if (this == t) return true
    if (t.signature == "sys::Func") return true
    if (t.isObj) return true
    if (t.name.size == 1 && t.pod.name == "sys") return true

    that := t.deref as FuncType
    if (that == null) return false

    // match return type (if void is needed, anything matches)
    if (!that.ret.isVoid && !ret.fits(that.ret)) return false

    // match params - it is ok for me to have less than
    // the type params (if I want to ignore them), but I
    // must have no more
    if (params.size > that.params.size) return false
    for (i:=0; i<params.size; ++i)
      if (!that.params[i].fits(params[i])) return false

    // this method works for the specified method type
    return true;
  }

  ParamDef[] toParamDefs(Location loc)
  {
    p := ParamDef[,]
    p.size = params.size
    for (i:=0; i<params.size; ++i)
    {
      p[i] = ParamDef.make(loc, params[i], names[i])
    }
    return p
  }

  override CType doParameterize(Int ch)
  {
    if ('A' <= ch && ch <= 'H')
    {
      index := ch - 'A'
      if (index < params.size) return params[index]
      return ns.objType
    }

    switch (ch)
    {
      case 'R': return ret
      default:  throw Err.make(ch.toChar)
    }
  }

  readonly CType[] params  // a, b, c ...
  readonly Str[] names     // parameter names
  readonly CType ret       // return type
  override readonly Str signature   // |a,b..n->r|
  override readonly Bool isGenericParameter
}

**************************************************************************
** GenericParameterType
**************************************************************************

**
** GenericParameterType models the generic parameter types
** sys::V, sys::K, etc.
**
class GenericParameterType : CType
{
  new make(CNamespace ns, Str name)
  {
    this.ns = ns
    this.name = name
    this.qname = "sys::$name"
  }

  override CNamespace ns
  override CPod pod() { return ns.sysPod }
  override Str name
  override Str qname
  override Str signature() { return qname }
  override Int flags() { return 0 }
  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }
  override Bool isGeneric() { return false }
  override Bool isParameterized() { return false }
  override Bool isGenericParameter() { return true }
  override once CType toListOf() { return ListType(this) }
  override CType base() { return ns.objType }
  override CType[] mixins() { return CType[,] }
  override Str:CSlot slots() { throw UnsupportedErr.make }
  override Str toStr() { return qname }
  private ListType listOf
}

**************************************************************************
** ParameterizedField
**************************************************************************

class ParameterizedField : CField
{
  new make(GenericType parent, CField generic)
  {
    this.parent = parent
    this.generic = generic
    this.fieldType = parent.parameterize(generic.fieldType)
    this.getter = ParameterizedMethod(parent, generic.getter)
    this.setter = ParameterizedMethod(parent, generic.setter)
  }

  override Str name()  { return generic.name }
  override Str qname() { return generic.qname }
  override Str signature() { return generic.signature }
  override Int flags() { return generic.flags }
  override Str toStr() { return generic.toStr }

  override CType fieldType
  override CMethod getter
  override CMethod setter
  override CType inheritedReturnType() { return fieldType }

  override Bool isParameterized() { return true }

  override readonly CType parent
  readonly CField generic
}

**************************************************************************
** ParameterizedMethod
**************************************************************************

**
** ParameterizedMethod models a parameterized CMethod
**
class ParameterizedMethod : CMethod
{
  new make(GenericType parent, CMethod generic)
  {
    this.parent = parent
    this.generic = generic

    this.returnType = parent.parameterize(generic.returnType)
    generic.params.map(this.params = CParam[,]) |CParam p->Obj|
    {
      return ParameterizedMethodParam.make(parent, p)
    }

    signature = "$returnType $name(" + params.join(", ") + ")"
  }

  override Str name()  { return generic.name }
  override Str qname() { return generic.qname }
  override Int flags() { return generic.flags }
  override Str toStr() { return signature }

  override Bool isParameterized()  { return true }

  override CType inheritedReturnType()  { return generic.inheritedReturnType }

  override readonly CType parent
  override readonly Str signature
  override readonly CMethod? generic
  override readonly CType returnType
  override readonly CParam[] params
}

**************************************************************************
** ParameterizedMethodParam
**************************************************************************

class ParameterizedMethodParam : CParam
{
  new make(GenericType parent, CParam generic)
  {
    this.generic = generic
    this.paramType = parent.parameterize(generic.paramType)
  }

  override Str name() { return generic.name }
  override Bool hasDefault() { return generic.hasDefault }
  override Str toStr() { return "$paramType $name" }

  override readonly CType paramType
  readonly CParam generic
}