//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

using math

**
** Asn provides utilities for creating `AsnObj`.
**
final const class Asn
{

//////////////////////////////////////////////////////////////////////////
// Primitives
//////////////////////////////////////////////////////////////////////////

  private static AsnObjBuilder builder() { AsnObjBuilder() }

  ** Create an [object builder]`AsnObjBuilder` and add the given tag if it
  ** is not null.
  static AsnObjBuilder tag(AsnTag? tag) { builder.tag(tag) }

  ** Convenience to create a universal 'Boolean'
  static AsnObj bool(Bool val) { builder.bool(val) }

  ** Convenience to create a universal 'Integer'.
  **
  ** See `AsnObjBuilder.int`
  static AsnObj int(Obj val) { builder.int(val) }

  ** Convenience to create a universal 'Bit String'
  **
  ** See `AsnObjBuilder.bits`
  static AsnObj bits(Buf bits){ builder.bits(bits) }

  ** Convenience to create a universal 'Octet String'
  **
  ** See `AsnObjBuilder.octets`
  static AsnObj octets(Obj val) { builder.octets(val) }

  ** Singleton for universal 'Null'
  static const AsnObj Null := AsnObj([AsnTag.univNull], null)

  ** Create an ASN.1 'Object Identifier' value (OID).
  **
  ** See `AsnObjBuilder.oid`
  static AsnOid oid(Obj val) { builder.oid(val) }

  // ** Create an ASN.1 `Real` value.
  // static AsnObj real(Float val, AsnTag? tag := null)
  // {
  //   AsnObj(chain(tag, AsnTag.univReal), val)
  // }

  ** Convenience to create a universal 'Enumerated' value
  static AsnObj asnEnum(Int val) { builder.asnEnum(val) }

  ** Convenience to create a universal 'Utf8String'
  static AsnObj utf8(Str val) { builder.utf8(val) }

  ** Convenience to create one of the ASN.1 string types.
  **
  ** See `AsnObjBuilder.str`
  **
  ** See `utf8` to easily create UTF-8 strings.
  static AsnObj str(Str val, AsnTag univ) { builder.str(val, univ) }

  ** Convenience to create a universal 'UTCTime'
  static AsnObj utc(DateTime ts) { builder.utc(ts) }

  ** Convenience to create a universal GeneralizedTime
  static AsnObj genTime(DateTime ts) { builder.genTime(ts) }

  ** Convenience to create a universal 'SEQUENCE'
  **
  ** See `AsnObjBuilder.seq`
  static AsnSeq seq(Obj items) { builder.seq(items) }

  ** Convenience to create a universal 'SET'
  **
  ** The 'items' parameter may be any of the values accepted by
  ** `seq`.
  static AsnSet set(Obj items) { builder.set(items) }

  @NoDoc static AsnObj any(Buf raw)
  {
    AsnBin([AsnTag.univAny], raw)
  }
}


**************************************************************************
** AsnObjBuilder
**************************************************************************

**
** Utility to build an `AsnObj`
**
class AsnObjBuilder
{
  new make()
  {
    this.tags = [,]
  }

  private AsnTag[] tags

  ** Add a tag to the object builder. Tags should be added in ther
  ** order they are specified in an ASN.1 type declaration. If the 'tag'
  ** is 'null', then this is a no-op.
  **
  ** Whenever a concrete `AsnObj` is built, the builder will clear
  ** all tags.
  **
  **   // [0] [1 APPLICATION] Boolean
  **   obj := AsnObjBuilder()
  **      .tag(AsnTag.context(0).implicit)
  **      .tag(AsnTag.app(1).implicit)
  **      .bool(true)
  This tag(AsnTag? tag)
  {
    if (tag != null) tags.add(tag)
    return this
  }

  ** Build an ASN.1 'Boolean' value
  AsnObj bool(Bool val)
  {
    finish(AsnObj(etags(AsnTag.univBool), val))
  }

  ** Build an ASN.1 'Integer' value. The 'val' may be either an `sys::Int`
  ** or a `math::BigInt`, but is always normalized to `math::BigInt`.
  AsnObj int(Obj val)
  {
    if (val is Int) val = BigInt.makeInt(val)
    if (val is BigInt) return finish(AsnObj(etags(AsnTag.univInt), val))
    throw ArgErr("Cannot create INTEGER from $val ($val.typeof)")
  }

  ** Build an ASN.1 'Bit String' value. The bits in the bit string
  ** are numbered from left to right. For example, bits '0-7' are in the
  ** first byte of the bits buffer.
  AsnObj bits(Buf bits)
  {
    finish(AsnBin(etags(AsnTag.univBits), bits))
  }

  ** Build an ASN.1 'Octet String' value. The 'val' may be:
  **  - a 'Str' - it will be converted to a Buf as '((Str)val).toBuf'
  **  - a 'Buf' containing the raw octets
  AsnObj octets(Obj val)
  {
    if (val is Str) val = ((Str)val).toBuf
    if (val is Buf) return finish(AsnBin(etags(AsnTag.univOcts), val))
    throw ArgErr("Cannot create OCTET STRING from $val ($val.typeof)")
  }

  ** Build an ASN.1 'Null' value
  AsnObj asnNull()
  {
    tags.isEmpty
      ? Asn.Null
      : finish(AsnObj(etags(AsnTag.univNull), null))
  }

  ** Build an ASN.1 'Object Identifier' value (OID). The 'val' may be:
  **  1. an 'Int[]' where each element of the list is a part of the oid.
  **  1. a 'Str' where each part of the oid is separated by '.'.
  **
  **   Asn.oid([1,2,3])
  **   Asn.oid("1.2.3")
  AsnOid oid(Obj val)
  {
    if (val is Str)
      val = ((Str)val).split('.').map |Str s->Int| { s.toInt }
    if (val is List && (((List)val).of == Int# || ((List)val).isEmpty))
      return finish(AsnOid(etags(AsnTag.univOid), (Int[])val))
    throw ArgErr("Cannot create OID from $val ($val.typeof)")
  }

  // ** Create an ASN.1 `Real` value.
  // static AsnObj real(Float val, AsnTag? tag := null)
  // {
  //   AsnObj(chain(tag, AsnTag.univReal), val)
  // }

  ** Build an ASN.1 'Enumerated' value.
  AsnObj asnEnum(Int val)
  {
    finish(AsnObj(etags(AsnTag.univEnum), BigInt(val)))
  }

  ** Build an ASN.1 'Utf8String' value.
  AsnObj utf8(Str val)
  {
    finish(AsnObj(etags(AsnTag.univUtf8), val))
  }

  ** Build one of the ASN.1 string types. The 'univ' parameter must
  ** be one of:
  ** - `AsnTag.univUtf8`
  ** - `AsnTag.univPrintStr`
  ** - `AsnTag.univIa5Str`
  ** - `AsnTag.univVisStr`
  **
  ** See `utf8` to easily create UTF-8 strings.
  AsnObj str(Str val, AsnTag univ)
  {
    switch (univ)
    {
      case AsnTag.univUtf8:
      case AsnTag.univPrintStr:
      case AsnTag.univIa5Str:
      case AsnTag.univVisStr:
        // fall-through
        return finish(AsnObj(etags(univ), val))
    }
    throw ArgErr("Unsupported universal type for ASN.1 string: $univ")
  }

  ** Build an ASN.1 'UTCTime' value
  AsnObj utc(DateTime ts)
  {
    finish(AsnObj(etags(AsnTag.univUtcTime), ts))
  }

  ** Build an ASN.1 'GeneralizedTime' value.
  AsnObj genTime(DateTime ts)
  {
    finish(AsnObj(etags(AsnTag.univGenTime), ts))
  }

  ** Build an ASN.1 'SEQUENCE' value
  ** The 'items' parameter may be:
  **  - An 'AsnItem[]' of raw items to add to the collection
  **  - An 'AsnObj[]'
  **  - A 'Str:AsnObj' - if the order of the sequence is important, you
  **  should ensure the map is ordered.
  AsnSeq seq(Obj items)
  {
    finish(AsnSeq(etags(AsnTag.univSeq), items))
  }

  ** Create an ASN.1 'SET' value
  ** The 'items' parameter may be any of the values accepted by
  ** `seq`.
  AsnSet set(Obj items)
  {
    finish(AsnSet(etags(AsnTag.univSet), items))
  }

  @NoDoc AsnObj any(Buf raw)
  {
    if (!tags.isEmpty) throw AsnErr("Should not specify tags for ANY: $tags")
    return finish(AsnBin(etags(AsnTag.univAny), raw))
  }

  private AsnObj finish(AsnObj obj)
  {
    this.tags.clear
    return obj
  }

  private AsnTag[] etags(AsnTag univ) { tags.dup.add(univ) }
}