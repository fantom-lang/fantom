//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

using math

class BerWriterTest : BerTest
{

  private Buf dummy := Buf()
  private BerWriter ber := BerWriter(dummy.out)

//////////////////////////////////////////////////////////////////////////
// BER Length
//////////////////////////////////////////////////////////////////////////

  Void testLength()
  {
    e := Buf().write(0x00)
    b := Buf()
    ber.writeLen(0, b.out)
    verifyBufEq(e, b)

    e.clear.write(127)
    ber.writeLen(127, b.clear.out)
    verifyBufEq(e, b)

    e.clear.write(0x81).write(128)
    ber.writeLen(128, b.clear.out)
    verifyBufEq(e, b)
  }

  Void testNegativeLengthFails()
  {
    b := Buf()
    verifyErr(AsnErr#) { ber.writeLen(-1, b.out) }
  }

//////////////////////////////////////////////////////////////////////////
// Boolean
//////////////////////////////////////////////////////////////////////////

  Void testBooleanEncoding()
  {
    e := Buf()
    verifyBufEq(e.clear.write(0xff), ber.writeBool(true))
    verifyBufEq(e.clear.write(0x00), ber.writeBool(false))
  }

  Void testUnivBooleanTag()
  {
    e := Buf().write(0x01)
    b := Buf()
    ber.writeTag(AsnTag.univBool, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Integer
//////////////////////////////////////////////////////////////////////////

  Void testIntegerEncoding()
  {
    e := Buf()

    e.write(0)
    verifyBufEq(e, ber.writeInt(0))

    e.clear.write(0x7f).write(0xff).write(0xff).write(0xff)
           .write(0xff).write(0xff).write(0xff).write(0xff)
    verifyBufEq(e, ber.writeInt(Int.maxVal))

    e.clear.write(0xff)
    verifyBufEq(e, ber.writeInt(-1))

    e.clear.write(0xfe).write(0x51)
    verifyBufEq(e, ber.writeInt(-431))

    e.clear.write(0x80).write(0).write(0).write(0)
           .write(0).write(0).write(0).write(0)
    verifyBufEq(e, ber.writeInt(Int.minVal))

    // BigInt
    i := BigInt(Int.maxVal).increment
    e.clear.write(0)
           .write(0x80).write(0).write(0).write(0)
           .write(0).write(0).write(0).write(0)
    verifyBufEq(e, ber.writeInt(i))
  }

  Void testUnivIntegerTag()
  {
    e := Buf().write(0x02)
    b := Buf()
    ber.writeTag(AsnTag.univInt, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Bit String
//////////////////////////////////////////////////////////////////////////

  Void testBitStringEncoding()
  {
    hex  := "cafe_babe"
    b    := Buf.fromHex(hex)
    bits := Asn.bits(Buf.fromHex(hex))

    e := Buf().write(0x00).writeBuf(b)
    verifyBufEq(e, ber.writeBits(bits))

    // empty bits
    bits = Asn.bits(Buf())
    verifyBufEq(e.clear.write(0x00), ber.writeBits(bits))

    // all zero bits
    bits = Asn.bits(Buf.fromHex("0000_0000_0000_0000_0000"))
    verifyBufEq(e.clear.write(0x00), ber.writeBits(bits))

    // one '1' bit at very end
    b = Buf.fromHex("0000_0000_0000_0000_0001")
    verifyBufEq(e.clear.write(0x00).writeBuf(b), ber.writeBits(Asn.bits(b.dup)))
  }

  Void testUnivBitStringTag()
  {
    e := Buf().write(0x03)
    b := Buf()
    ber.writeTag(AsnTag.univBits, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Octet String
//////////////////////////////////////////////////////////////////////////

  Void testOctetStringEncoding()
  {
    text := "Octet String"
    e    := text.toBuf
    os   := Asn.octets(text.toBuf)
    verifyBufEq(e, ber.writeOcts(os))

    // empty octet string
    os = Asn.octets("".toBuf)
    e.clear
    verifyBufEq(e, ber.writeOcts(os))
  }

  Void testUnivOctetStringTag()
  {
    e := Buf().write(0x04)
    b := Buf()
    ber.writeTag(AsnTag.univOcts, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Null
//////////////////////////////////////////////////////////////////////////

  Void testNullEncoding()
  {
    b := ber.writeNull()
    verify(b.isEmpty)
  }

  Void testUnivNullTag()
  {
    e := Buf().write(0x05)
    b := Buf()
    ber.writeTag(AsnTag.univNull, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Oid
//////////////////////////////////////////////////////////////////////////

  Void testOidEncoding()
  {
    oid := Asn.oid([1,3,6,0,0xffffe])
    verifyBufEq(octets([43,6,0,191,255,126]), ber.writeOid(oid))

    oid = Asn.oid("0.39")
    verifyBufEq(octets([39]), ber.writeOid(oid))

    oid = Asn.oid("1.39")
    verifyBufEq(octets([79]), ber.writeOid(oid))

    // 0111_1000
    oid = Asn.oid("2.40")
    verifyBufEq(octets([120]), ber.writeOid(oid))

    // 10010000|10000000|100000000|100000000|01001111
    oid = Asn.oid([2,0xffffffff])
    verifyBufEq(octets([0x90,0x80,0x80,0x80,0x4f]), ber.writeOid(oid))

    // 0111_1111
    oid = Asn.oid("2.47")
    verifyBufEq(octets([0x7f]), ber.writeOid(oid))

    oid = Asn.oid("2.48")
    verifyBufEq(octets([0x81,0x00]), ber.writeOid(oid))

    oid = Asn.oid("2.100.3")
    verifyBufEq(octets([0x81, 0x34, 0x03]), ber.writeOid(oid))

    oid = Asn.oid("2.560")
    verifyBufEq(octets([133,0]), ber.writeOid(oid))

    oid = Asn.oid("2.16843570")
    verifyBufEq(octets([0x88,0x84,0x87,0x02]), ber.writeOid(oid))
  }

  Void testBadOids()
  {
    oid := Asn.oid("0")
    verifyErr(AsnErr#) { ber.writeOid(oid) }

    oid = Asn.oid("3.1.2")
    verifyErr(AsnErr#) { ber.writeOid(oid) }

    oid = Asn.oid("1.3.-1")
    verifyErr(AsnErr#) { ber.writeOid(oid) }
  }

  Void testUnivOidTag()
  {
    e := Buf().write(0x06)
    b := Buf()
    ber.writeTag(AsnTag.univOid, Format.primitive, b.out)
    verifyBufEq(e, b)
  }

//////////////////////////////////////////////////////////////////////////
// Strings
//////////////////////////////////////////////////////////////////////////

  Void testStrings()
  {
    ["", "foo"].each |s|
    {
      e := s.toBuf
      verifyBufEq(e, ber.writeUtf8(Asn.utf8(s).val))
      verifyBufEq(e, ber.writeUtf8(Asn.str(s, AsnTag.univPrintStr).val))
      verifyBufEq(e, ber.writeUtf8(Asn.str(s, AsnTag.univIa5Str).val))
      verifyBufEq(e, ber.writeUtf8(Asn.str(s, AsnTag.univVisStr).val))
    }
  }

  Void testUnivStringTags()
  {
    b := Buf()
    ber.writeTag(AsnTag.univUtf8, Format.primitive, b.out)
    verifyEq(12, b.flip.read)
    ber.writeTag(AsnTag.univPrintStr, Format.primitive, b.clear.out)
    verifyEq(19, b.flip.read)
    ber.writeTag(AsnTag.univIa5Str, Format.primitive, b.clear.out)
    verifyEq(22, b.flip.read)
    ber.writeTag(AsnTag.univVisStr, Format.primitive, b.clear.out)
    verifyEq(26, b.flip.read)
  }

//////////////////////////////////////////////////////////////////////////
// UtcTime
//////////////////////////////////////////////////////////////////////////

  Void testUtcTime()
  {
    ts  := Date.fromStr("2015-03-24").midnight(TimeZone.utc)
    verifyBufEq("1503240000Z".toBuf, ber.writeUtcTime(ts))
    ts = DateTime(1980, Month.mar, 24, 23, 59, 59, 0, TimeZone.utc)
    verifyBufEq("800324235959Z".toBuf, ber.writeUtcTime(ts))

    // test nano-second (millsecond) formatting
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 000_000_001, TimeZone.utc)
    verifyBufEq("000324235959Z".toBuf, ber.writeUtcTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 000_900_000, TimeZone.utc)
    verifyBufEq("000324235959Z".toBuf, ber.writeUtcTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 001_000_000, TimeZone.utc)
    verifyBufEq("000324235959.001Z".toBuf, ber.writeUtcTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 010_000_000, TimeZone.utc)
    verifyBufEq("000324235959.01Z".toBuf, ber.writeUtcTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 100_000_000, TimeZone.utc)
    verifyBufEq("000324235959.1Z".toBuf, ber.writeUtcTime(ts))
  }

  Void testUnivUtcTimeTag()
  {
    b := Buf()
    ber.writeTag(AsnTag.univUtcTime, Format.primitive, b.out)
    verifyEq(23, b.flip.read)
  }

//////////////////////////////////////////////////////////////////////////
// GenTime
//////////////////////////////////////////////////////////////////////////

  Void testGenTime()
  {
    // These tests are only for UTC (i.e. DER encodings)
    ts  := Date.fromStr("2015-03-24").midnight(TimeZone.utc)
    verifyBufEq("201503240000Z".toBuf, ber.writeGenTime(ts))
    ts = DateTime(1980, Month.mar, 24, 23, 59, 59, 0, TimeZone.utc)
    verifyBufEq("19800324235959Z".toBuf, ber.writeGenTime(ts))

    // test nano-second (millsecond) formatting
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 000_000_001, TimeZone.utc)
    verifyBufEq("20000324235959Z".toBuf, ber.writeGenTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 000_900_000, TimeZone.utc)
    verifyBufEq("20000324235959Z".toBuf, ber.writeGenTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 001_000_000, TimeZone.utc)
    verifyBufEq("20000324235959.001Z".toBuf, ber.writeGenTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 010_000_000, TimeZone.utc)
    verifyBufEq("20000324235959.01Z".toBuf, ber.writeGenTime(ts))
    ts = DateTime(2000, Month.mar, 24, 23, 59, 59, 100_000_000, TimeZone.utc)
    verifyBufEq("20000324235959.1Z".toBuf, ber.writeGenTime(ts))
  }

  Void testUnivGenTimeTag()
  {
    b := Buf()
    ber.writeTag(AsnTag.univGenTime, Format.primitive, b.out)
    verifyEq(24, b.flip.read)
  }

//////////////////////////////////////////////////////////////////////////
// Sequence
//////////////////////////////////////////////////////////////////////////

  Void testSequenceEncoding()
  {
    // empty sequence
    e := Buf()
    seq := Asn.seq([,])
    verifyBufEq(e, ber.writeColl(seq))

    // one primitive
    seq = Asn.seq([Asn.int(15)])
    e.clear.write(0x02).write(0x01).write(15)
    verifyBufEq(e, ber.writeColl(seq))

    // mixed sequence
    seq = Asn.seq([Asn.int(15), Asn.Null])
    e.clear.write(0x02).write(0x01).write(15).write(0x05).write(0x00)
    verifyBufEq(e, ber.writeColl(seq))
  }

  Void testUnivSequenceTag()
  {
    e := Buf().write(0x30)
    b := Buf()
    ber.writeTag(AsnTag.univSeq, Format.constructed, b.out)
    verifyBufEq(e, b)
  }
}