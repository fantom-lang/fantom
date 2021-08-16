//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

using math

**
** BerReader decodes ASN.1 objects using the Basic Encoding Rules
**
class BerReader
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(InStream in)
  {
    this.in = in
  }

  private InStream in

//////////////////////////////////////////////////////////////////////////
// BerReader
//////////////////////////////////////////////////////////////////////////

  Bool close() { in.close }

  AsnObj readObj(AsnObj? spec := null) { doReadObj(this.in, spec) }

  private AsnObj doReadObj(InStream in, AsnObj? spec)
  {
    tag := readTag(in)
    len := readLen(in)
    val := in.readBufFully(null, len)
    return tryUniversal(tag, val) ?: AsnBin([tag, AsnTag.univAny], val).decode(spec)
  }

  @NoDoc AsnTag readTag(InStream in := this.in)
  {
    // only simple, un-constructed (1-byte) tags are supported right now (id < 31)
    octet     := in.read
    classMask := octet.and(0xc0)
    cls       := AsnTagClass.vals.find { it.mask == classMask }
    id        := octet.and(0x1f)
    if (id >= 31) throw UnsupportedErr("only simple ids supported: $id")
    return AsnTag(cls, id, cls.isUniv ? AsnTagMode.explicit : AsnTagMode.implicit)
  }

  @NoDoc Int readLen(InStream in := this.in)
  {
    octet := in.read
    if (octet.and(0x80) == 0) return octet
    else
    {
      // turn off top bit to get number of octets that compose the length
      numOctets := octet.and(0x7f)
      len := 0
      while (numOctets > 0)
      {
        len = len.shiftl(8).or(in.read)
        --numOctets
      }
      return len
    }
  }

  private AsnObj? tryUniversal(AsnTag tag, Buf val)
  {
    if (!tag.cls.isUniv) return null
    if (tag == AsnTag.univAny) return null

    in := val.in
    switch (tag)
    {
      case AsnTag.univSeq:     return Asn.seq(readItems(in))
      case AsnTag.univBool:    return Asn.bool(readBool(in))
      case AsnTag.univInt:     return Asn.int(readInt(in))
      case AsnTag.univBits:    return Asn.bits(readBits(in))
      case AsnTag.univOcts:    return Asn.octets(readOcts(in))
      case AsnTag.univNull:    return Asn.Null
      case AsnTag.univOid:     return Asn.oid(readOid(in))
      case AsnTag.univEnum:    return Asn.asnEnum(readInt(in).toInt)
      case AsnTag.univUtf8:
      case AsnTag.univPrintStr:
      case AsnTag.univIa5Str:
      case AsnTag.univVisStr:
        // fall-through
        return Asn.str(readUtf8(in), tag)
      case AsnTag.univUtcTime: return Asn.utc(readUtcTime(in))
      case AsnTag.univGenTime: return Asn.genTime(readGenTime(in))
      case AsnTag.univSet:     return Asn.set(readItems(in))
    }
    throw AsnErr("No reader for universal tag: ${tag}")
  }

//////////////////////////////////////////////////////////////////////////
// Bool
//////////////////////////////////////////////////////////////////////////

  @NoDoc Bool readBool(InStream in := this.in)
  {
    in.read != 0x00
  }

//////////////////////////////////////////////////////////////////////////
// Integer
//////////////////////////////////////////////////////////////////////////

  @NoDoc BigInt readInt(InStream in := this.in)
  {
    bytes := Buf()
    octet := in.read
    if (octet == null) return BigInt.zero
    while(octet != null)
    {
      bytes.write(octet)
      octet = in.read
    }
    return BigInt(bytes.seek(0))
  }

//////////////////////////////////////////////////////////////////////////
// Bit String
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf readBits(InStream in := this.in)
  {
    // first octet is number of unused bits in last octet
    unused := in.read
    return in.readAllBuf
  }

  // OLD WAY: this is actually more "correct" in terms of handling
  // unused bits, but I'm not sure it matters in practice. Here for reference
  // virtual Buf readBits(InStream in)
  // {
  //    // first octet is number of unused bits in last octet
  //   unused := in.read
  //   buf := StrBuf()

  //   octet := in.read
  //   while (octet != null)
  //   {
  //     buf.add(octet.toRadix(2, 8))
  //     octet = in.read
  //   }
  //   return buf[0..<(buf.size - unused)]
  // }

//////////////////////////////////////////////////////////////////////////
// Bit String
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf readOcts(InStream in := this.in)
  {
    in.readAllBuf
  }

//////////////////////////////////////////////////////////////////////////
// Object Identifier
//////////////////////////////////////////////////////////////////////////

  @NoDoc Int[] readOid(InStream in := this.in)
  {
    ids   := Int[,]
    octet := in.read
    if (octet == null) throw AsnErr("Object Identifier must have at least one octet.")
    while (octet != null)
    {
      id := 0
      if (octet < 128) id = octet
      else
      {
        while(true)
        {
          // bit 8 is the more bit, so turn it off and shift in the lower 7 bits
          id = id.shiftl(7).or(octet.and(0x7f))

          // if bit 8 is zero this is the last octet for this id
          if (octet.and(0x80) == 0) break

          octet = in.read
          if (octet == null) throw AsnErr("Unexpected end of oid: $ids")
        }
      }

      // special handling for first id.
      if (ids.isEmpty)
      {
        if (0 <= id && id <= 39) ids.add(0)
        else if (40 <= id && id <= 79) { ids.add(1); id -= 40 }
        else { ids.add(2); id -= 80 }
      }

      ids.add(id)
      octet = in.read
    }
    return ids
  }

//////////////////////////////////////////////////////////////////////////
// Strings
//////////////////////////////////////////////////////////////////////////

  ** All the currently supported string types are utf-8, or a proper subset (ascii)
  @NoDoc Str readUtf8(InStream in := this.in)
  {
    bufToStr(readOcts(in), Charset.utf8)
  }

  private static Str bufToStr(Buf buf, Charset charset)
  {
    buf.charset = charset
    return buf.readAllStr(false)
  }

//////////////////////////////////////////////////////////////////////////
// Timestamps
//////////////////////////////////////////////////////////////////////////

  @NoDoc DateTime readUtcTime(InStream in := this.in)
  {
    enc := in.readAllStr
    return DateTime.fromLocale(enc, timePattern(enc, false))
  }

  @NoDoc DateTime readGenTime(InStream in := this.in)
  {
    enc := in.readAllStr
    return DateTime.fromLocale(enc, timePattern(enc, true))
  }

  private static Str timePattern(Str enc, Bool forGenTime)
  {
    pattern := StrBuf()
    pattern.add(forGenTime ? "YYYY" : "YY")
    pattern.add("MMDDhhmm")
    if (pattern.size == enc.size) return pattern.toStr

    // now check all the optional parts
    // pos starts at index of optional seconds
    pos := pattern.size
    if (enc[pos].isDigit) { pattern.add("ss"); pos += 2 }
    if (enc.getSafe(pos) == '.') { pattern.add(".FFF"); pos += 4 }
    switch (enc[-1])
    {
      case 'Z':
      case '+':
      case '-':
        pattern.add("z")
    }
    return pattern.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Collections
//////////////////////////////////////////////////////////////////////////

  @NoDoc AsnItem[] readItems(InStream in := this.in)
  {
    acc := AsnItem[,]
    while (in.peek != null)
    {
      val := this.doReadObj(in, null)
      acc.add(AsnItem(val))
    }
    return acc
  }
}