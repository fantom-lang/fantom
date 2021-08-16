//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//

**
** Models an ASN.1 binary primitive type. These types are backed by a Buf.
**
@NoDoc const class AsnBin : AsnObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(AsnTag[] tags, Buf buf) : super(tags, Unsafe(buf.dup))
  {
  }

//////////////////////////////////////////////////////////////////////////
// AsnBin
//////////////////////////////////////////////////////////////////////////

  ** Does this represent the ASN.1 'ANY' type
  override Bool isAny() { this.univTag == AsnTag.univAny }

  ** Get the number of octets in this binary type
  Int size() { unsafeBuf.size }

  ** Convenience to read the contents of the binary object as a UTF-8 string
  Str readAllStr() { forRead.readAllStr(false) }

  ** Get a safe copy of the contents of this binary object
  override Buf buf() { unsafeBuf.dup }

  internal Buf forRead() { unsafeBuf.seek(0) }

  private Buf unsafeBuf() { ((Unsafe)val).val }

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

  AsnObj decode(AsnObj? spec := null)
  {
    if (spec == null) return this

    r := BerReader(unsafeBuf.in)
    t := this.tags[0..<-1].add(spec.univTag)
    switch (spec.univTag)
    {
      case AsnTag.univSeq:      return AsnSeq(t, r.readItems)
      case AsnTag.univBool:     return AsnObj(t, r.readBool)
      case AsnTag.univInt:      return AsnObj(t, r.readInt)
      case AsnTag.univBits:     return AsnBin(t, r.readBits)
      case AsnTag.univOcts:     return AsnBin(t, r.readOcts)
      case AsnTag.univNull:     return AsnObj(t, null)
      case AsnTag.univOid:      return AsnOid(t, r.readOid)
      case AsnTag.univEnum:     return AsnObj(t, r.readInt)
      case AsnTag.univUtf8:
      case AsnTag.univPrintStr:
      case AsnTag.univIa5Str:
      case AsnTag.univVisStr:
        // fall-through
        return AsnObj(t, r.readUtf8)
      case AsnTag.univUtcTime:  return AsnObj(t, r.readUtcTime)
      case AsnTag.univGenTime:  return AsnObj(t, r.readGenTime)
      case AsnTag.univSet:      return AsnSet(t, r.readItems)

    }
    throw AsnErr("No reader for type: $spec")
  }

//////////////////////////////////////////////////////////////////////////
// AsnObj
//////////////////////////////////////////////////////////////////////////

  override AsnBin push(AsnTag tag)
  {
    AsnBin([tag].addAll(this.tags), forRead)
  }

  protected override Int valHash()
  {
    unsafeBuf.toHex.hash
  }

  protected override Bool valEquals(AsnObj obj)
  {
    that := obj as AsnBin
    if (that == null) return false
    if (this.size != that.size) return false
    if (this.unsafeBuf.toHex != that.unsafeBuf.toHex) return false
    return true
  }
}