//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

using math

**
** A tagged ASN.1 value
**
const class AsnObj
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  protected new make(AsnTag[] tags, Obj? val)
  {
    idx := tags.findIndex |tag| { tag.cls.isUniv }
    if (idx == null) throw ArgErr("No UNIVERSAL tag specified")
    if (idx != tags.size - 1) throw ArgErr("UNIVERSAL tag must be last: ${idx} != ${tags.size-1}")
    this.tags = tags
    this.val  = val
  }

  ** The tags for this object.
  const AsnTag[] tags

  ** The value for this object.
  const Obj? val

//////////////////////////////////////////////////////////////////////////
// Value
//////////////////////////////////////////////////////////////////////////

  ** Get the value as a `sys::Bool`
  Bool bool() { val }

  ** Is this object's universal tag a 'Boolean'
  Bool isBool() { univTag == AsnTag.univBool }

  ** Get the value as an `sys::Int`. If the value is a `math::BigInt` you may lose
  ** both precision and sign. Use `bigInt` to get the value explicitly
  ** as a `math::BigInt`.
  Int int()
  {
    if (val is BigInt) return ((BigInt)val).toInt
    return val
  }

  ** Is this object's universal tag an 'Integer'
  Bool isInt() { univTag == AsnTag.univInt }

  ** Get the value as a `math::BigInt`.
  BigInt bigInt()
  {
    if (val is Int) return BigInt.makeInt(val)
    return val
  }

  ** Get any of the  binary values as a `sys::Buf`. The Buf will be a safe copy
  ** that can be modified. Throws `AsnErr` if the value is not a binary value.
  virtual Buf buf() { throw AsnErr("Not a binary type: ${typeof}") }

  ** Is this object's universal tag an 'Octet String'
  Bool isOcts() { univTag == AsnTag.univOcts }

  ** Is this an ASN.1 'Null' value
  Bool isNull() { val == null && univTag == AsnTag.univNull }

  ** Get this object as an `AsnOid`
  AsnOid oid() { this }

  ** Is this object's universal tag an 'Object Identifier'
  Bool isOid() { univTag == AsnTag.univOid }

  ** Get the value as a `sys::Str`
  Str str() { val }

  ** Get the value as a `sys::DateTime` timestamp
  DateTime ts() { val }

  ** Get this object as an `AsnColl`
  AsnColl coll() { this }

  ** Get this object as an `AsnSeq`
  AsnSeq seq() { this }

  @NoDoc virtual Bool isAny() { false }

//////////////////////////////////////////////////////////////////////////
// Tagging
//////////////////////////////////////////////////////////////////////////

  ** Push a tag to the front of the tag chain for this value. Returns
  ** a new instance of this object with the current value.
  **
  **   AsnObj.int(123).tag(AsnTag.implicit(TagClass.context, 0))
  **     => [0] IMPLICIT [UNIVERSAL 2]
  **   AsnObj.int(123).tag(AsnTag.explicit(TagClass.app, 1))
  **     => [APPLICATION 1] EXPLICIT [UNIVERSAL 2]
  virtual AsnObj push(AsnTag tag)
  {
    typeof.method("make").call([tag].addAll(this.tags), this.val)
  }

  ** Apply rules for 'EXPLICIT' and 'IMPLICIT' tags to obtain
  ** the set of effective tags for encoding this object.
  AsnTag[] effectiveTags()
  {
    acc := AsnTag[,]
    AsnTag? prev := null
    tags.each |tag|
    {
      if (prev == null) acc.add(tag)
      else if (prev.mode === AsnTagMode.explicit) acc.add(tag)
      prev = tag
    }
    return acc
  }

  ** Get the single effective tag for this object. Throws an error
  ** if there are multiple effective tags
  AsnTag tag()
  {
    etags := this.effectiveTags
    if (etags.size > 1) throw AsnErr("Multiple effective tags: $etags")
    return etags.first
  }

  ** Get the univ tag for this object
  AsnTag univTag() { tags.last }

  ** Is this a primitive type?
  Bool isPrimitive()
  {
    switch (univTag)
    {
      case AsnTag.univSeq:
      case AsnTag.univSet:
        return false
      default:
        return true
    }
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  final override Int hash()
  {
    res := 31 + tags.hash
    res = (res * 31) + valHash
    return res
  }

  protected virtual Int valHash() { val?.hash ?: 0}

  final override Bool equals(Obj? obj)
  {
    if (this === obj) return true
    that := obj as AsnObj
    if (that == null) return false

    // for objects, tag equality is strict
    these := this.tags
    those := that.tags
    if (these.size != those.size) return false
    eq := these.all |t,i| { t.strictEquals(those[i]) }
    if (!eq) return false

    return valEquals(that)
  }

  protected virtual Bool valEquals(AsnObj that) { this.val == that.val }

  override Str toStr()
  {
    "${tags} ${valStr}"
  }

  protected virtual Str valStr() { "${val}" }
}