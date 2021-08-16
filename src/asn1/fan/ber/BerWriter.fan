//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

using math

**
** BerWriter encodes ASN.1 objects using the Basic Encoding Rules.
**
class BerWriter
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  static Buf toBuf(AsnObj obj, Buf buf := Buf())
  {
    BerWriter(buf.out).write(obj)
    return buf.flip
  }

  new make(OutStream out)
  {
    this.out = out
  }

  private OutStream out

//////////////////////////////////////////////////////////////////////////
// BerWriter
//////////////////////////////////////////////////////////////////////////

  Bool close() { out.close }

  This write(AsnObj obj) { doWrite(obj, out) }

  private This doWrite(AsnObj obj, OutStream out)
  {
    tlv := writeVal(obj)

    // Any is assumed to be already encoded, so we
    // don't need to write any tags
    if (obj.isAny)
    {
      out.writeBuf(tlv.seek(0))
      return this
    }

    format := obj.isPrimitive ? Format.primitive : Format.constructed
    obj.effectiveTags.reverse.each |tag, i|
    {
      temp := Buf(tlv.size + 4)
      if (i != 0) format = Format.constructed

      // TLV
      writeTag(tag, format, temp.out)
        .writeLen(tlv.size, temp.out)
      temp.writeBuf(tlv.seek(0))

      tlv = temp
    }
    out.writeBuf(tlv.seek(0))

    return this
  }

//////////////////////////////////////////////////////////////////////////
// T - Tag
//////////////////////////////////////////////////////////////////////////

  @NoDoc This writeTag(AsnTag tag, Format format, OutStream out)
  {
    v := tag.cls.mask.or(format.mask)
    if (tag.id < 31)
    {
      v = v.or(tag.id)
      out.write(v)
    }
    else
    {
      // TODO: special encoding for ids >= 31
      throw UnsupportedErr("Tag id '${tag.id}' is not supported")
    }
    return this
  }

//////////////////////////////////////////////////////////////////////////
// L - Length
//////////////////////////////////////////////////////////////////////////

  @NoDoc This writeLen(Int len, OutStream out)
  {
    if (len < 0) throw AsnErr("Length cannot be negative: $len")

    if (len < 128) out.write(len)
    else
    {
      // definite long-form
      octets := Int[,]
      while (len != 0)
      {
        octets.add(len.and(0xff))
        len = len.shiftr(8)
      }
      numOctets := octets.size
      if (numOctets > 127) throw AsnErr("Too many octets for encoding length: $len")

      out.write(numOctets.or(0x80))
      octets.eachr |octet| { out.write(octet) }
    }
    return this
  }

//////////////////////////////////////////////////////////////////////////
// V - Value
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeVal(AsnObj obj, Buf buf := Buf(64))
  {
    switch (obj.univTag)
    {
      case AsnTag.univSeq:
      case AsnTag.univSet:
        // fall-through
        return writeColl(obj, buf)
      case AsnTag.univBool:     return writeBool(obj.bool, buf)
      case AsnTag.univInt:      return writeInt(obj.bigInt, buf)
      case AsnTag.univBits:     return writeBits(obj, buf)
      case AsnTag.univOcts:     return writeOcts(obj, buf)
      case AsnTag.univNull:     return writeNull(buf)
      case AsnTag.univOid:      return writeOid(obj.oid, buf)
      case AsnTag.univEnum:     return writeInt(obj.bigInt, buf)
      case AsnTag.univUtf8:
      case AsnTag.univPrintStr:
      case AsnTag.univIa5Str:
      case AsnTag.univVisStr:
        // fall-through
        return writeUtf8(obj.str, buf)
      case AsnTag.univUtcTime:  return writeUtcTime(obj.ts, buf)
      case AsnTag.univGenTime:  return writeGenTime(obj.ts, buf)
      case AsnTag.univAny:      return writeAny(obj, buf)
      default: throw AsnErr("No writer for $obj")
    }
    return buf
  }

//////////////////////////////////////////////////////////////////////////
// Any
//////////////////////////////////////////////////////////////////////////

  @NoDoc virtual Buf writeAny(AsnBin any, Buf buf:= Buf(any.size))
  {
    buf.writeBuf(any.forRead)
  }

//////////////////////////////////////////////////////////////////////////
// Boolean
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeBool(Bool val, Buf buf := Buf(1))
  {
    return val ? buf.write(0xff) : buf.write(0x00)
  }

//////////////////////////////////////////////////////////////////////////
// Integer
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeInt(Obj val, Buf buf := Buf())
  {
    if (val is Int) val = BigInt.makeInt(val)
    int := val as BigInt ?: throw ArgErr("Not an int: $val ($val.typeof)")
    if (int == BigInt.zero) return buf.write(0)
    return buf.writeBuf(int.toBuf)
  }

//////////////////////////////////////////////////////////////////////////
// Bit String
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeBits(AsnBin bits, Buf buf := Buf(bits.size+1))
  {
    raw := bits.buf

    // TODO: not sure if this is a problem or not, but since
    // we model bits as underlying Buf, we always encode full
    // last octet and we don't really know if trailing zeroes
    // in that octet are unused or not.
    //
    // So we always write '0' for number of unused bits
    buf.write(0x00)

    // if all zero bits, then we are done
    allZero := raw.toHex.all |c| { c == '0'}
    return allZero ? buf : buf.writeBuf(raw)
  }

//////////////////////////////////////////////////////////////////////////
// Octets
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeOcts(AsnBin octets, Buf buf := Buf(octets.size))
  {
    buf.writeBuf(octets.buf)
  }

//////////////////////////////////////////////////////////////////////////
// Null
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeNull(Buf buf := Buf(0))
  {
    buf
  }

//////////////////////////////////////////////////////////////////////////
// Object Identifier
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeOid(AsnOid oid, Buf buf := Buf(64))
  {
    ids := oid.ids

    // sanity check
    if (ids.size < 2) throw AsnErr("Oid must have at least two arcs: $ids")
    if ((ids[0] > 2)                 ||
        (ids[0] == 0 && ids[1] > 39) ||
        (ids[0] == 1 && ids[1] > 39)) throw AsnErr("Invalid initial arc ${ids[0]}.${ids[1]}: ")

    // special encoding for first 2 arcs
    first := (ids[0] * 40) + ids[1]

    [first].addAll(ids[2..-1]).each |subId|
    {
      if (subId < 0) throw AsnErr("Negative sub-id: $subId")
      if (subId < 128) buf.write(subId.and(0x7f))
      else
      {
        octets := Int[,]
        // last octet must have zero in bit 8.
        octets.add(subId.and(0x7f))
        subId = subId.shiftr(7)
        while (subId != 0)
        {
          // all other octets must "more" bit set (bit 8)
          octets.add(subId.and(0x7f).or(0x80))
          subId = subId.shiftr(7)
        }
        octets.reverse.each { buf.write(it) }
      }
    }
    return buf
  }

//////////////////////////////////////////////////////////////////////////
// Strings
//////////////////////////////////////////////////////////////////////////

  ** All the supported string types are utf-8 or a proper subset (ascii)
  @NoDoc Buf writeUtf8(Str str, Buf buf := Buf(str.chars.size))
  {
    buf.writeBuf(str.toBuf(Charset.utf8))
  }

//////////////////////////////////////////////////////////////////////////
// Timestamps
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeUtcTime(DateTime ts, Buf buf := Buf(30))
  {
    writeTimestamp(ts, buf, false)
  }

  @NoDoc Buf writeGenTime(DateTime ts, Buf buf := Buf(30))
  {
    writeTimestamp(ts, buf, true)
  }

  ** NOTE: we always convert the time stamp to UTC. This makes
  ** the encoding a valid DER encoding also.
  private Buf writeTimestamp(DateTime ts, Buf buf, Bool isGenTime)
  {
    // convert to UTC
    dt := ts.toTimeZone(TimeZone.utc)
    millis := dt.nanoSec.toDuration.toMillis

    // build up pattern
    pattern := StrBuf()
    pattern.add("YY")
    // GenTime is 4-digit year
    if (isGenTime) pattern.add ("YY")
    pattern.add("MM").add("DD")
    pattern.add("hh").add("mm")
    if (dt.sec != 0) pattern.add("ss")
    if (millis != 0) pattern.add(".FFF")
    pattern.add("z")

    // get encoded format and write it
    enc := dt.toLocale(pattern.toStr, Locale.en)
    return buf.writeChars(enc)
  }

//////////////////////////////////////////////////////////////////////////
// Collections
//////////////////////////////////////////////////////////////////////////

  @NoDoc Buf writeColl(AsnColl coll, Buf buf := Buf())
  {
    coll.vals.each |AsnObj val|
    {
      doWrite(val, buf.out)
    }
    return buf
  }
}

**************************************************************************
** Format
**************************************************************************

@NoDoc enum class Format
{
  primitive(0x00),
  constructed(0x20)

  private new make(Int mask) { this.mask = mask }
  const Int mask
}