//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//

using math

class BerReaderTest : BerTest
{

  protected BerReader ber(Buf bytes := Buf()) { BerReader(bytes.in) }

//////////////////////////////////////////////////////////////////////////
// Ber Length
//////////////////////////////////////////////////////////////////////////

  Void testReadLen()
  {
    verifyEq(0,     ber(octets([0]).flip).readLen)
    verifyEq(127,   ber(octets([127]).flip).readLen)
    verifyEq(128,   ber(octets([0x81,128]).flip).readLen)
    verifyEq(255,   ber(octets([0x81,0xff]).flip).readLen)
    verifyEq(256,   ber(octets([0x82,0x01,0x00]).flip).readLen)
    verifyEq(65535, ber(octets([0x82,0xff,0xff]).flip).readLen)
  }

//////////////////////////////////////////////////////////////////////////
// Boolean
//////////////////////////////////////////////////////////////////////////

  Void testReadBoolean()
  {
    verifyEq(false, ber.readBool(octIn([0])))
    (1..0xff).each { verifyEq(true, ber.readBool(octIn([it]))) }
  }

  Void testReadBooleanType()
  {
    verifyEq(Asn.bool(true), ber(enc(Asn.bool(true))).readObj)
    verifyEq(Asn.bool(false), ber(enc(Asn.bool(false))).readObj)

    // verify get Any
    b := Asn.tag(AsnTag.context(1).implicit).bool(true)
    verify(ber(enc(b)).readObj.isAny)

    // test with spec
    verifyEq(b, ber(enc(b)).readObj(b))
  }

//////////////////////////////////////////////////////////////////////////
// Integer
//////////////////////////////////////////////////////////////////////////

  Void testReadInteger()
  {
    verifyEq(0,          ber.readInt(octIn([0])).toInt)
    verifyEq(-1,         ber.readInt(octIn([0xff])).toInt)
    verifyEq(-431,       ber.readInt(octIn([0xfe, 0x51])).toInt)
    verifyEq(Int.maxVal, ber.readInt(octIn([0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])).toInt)
    verifyEq(Int.minVal, ber.readInt(octIn([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])).toInt)
    verifyEq(BigInt(Int.maxVal).increment, ber.readInt(octIn([0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])))
  }

  Void testReadIntegerType()
  {
    i := Asn.int(12345)
    verifyEq(i, ber(enc(i)).readObj)

    // verify get Any
    i = Asn.int(-12345).push(AsnTag.context(0).implicit)
    verify(ber(enc(i)).readObj.isAny)

    // test with spec
    verifyEq(i, ber(enc(i)).readObj(i))
  }

//////////////////////////////////////////////////////////////////////////
// Bit String
//////////////////////////////////////////////////////////////////////////

  Void testReadBitString()
  {
    verifyBufEq(Buf(), ber.readBits(octIn([0])))
    verifyBufEq(Buf.fromHex("cafe_babe"), ber.readBits(octIn([0,0xca,0xfe,0xba,0xbe])))
  }

  Void testReadBitStringType()
  {
    hex  := Buf.fromHex("dead_beef")
    bits := Asn.bits(hex)
    verifyEq(bits, ber(enc(bits)).readObj)

    // verify get Any
    bits = bits.push(AsnTag.context(0).implicit)
    verify(ber(enc(bits)).readObj.isAny)

    // test with spec
    verifyEq(bits, ber(enc(bits)).readObj(bits))
  }

//////////////////////////////////////////////////////////////////////////
// Octet String
//////////////////////////////////////////////////////////////////////////

  Void testReadOctetString()
  {
    verifyBufEq(Buf(), ber.readOcts(octIn([,])))
    verifyBufEq("Hello".toBuf, ber.readOcts(octIn(['H','e','l','l','o'])))
  }

  Void testReadOctetStringType()
  {
    text := "An octet string is not a string of chars, it's a string of bytes."
    s := Asn.octets(text.toBuf)
    verifyEq(s, ber(enc(s)).readObj)

    // verify get Any
    s = s.push(AsnTag.context(0).implicit)
    verify(ber(enc(s)).readObj.isAny)

    // test with spec
    verifyEq(s, ber(enc(s)).readObj(s))
  }

//////////////////////////////////////////////////////////////////////////
// Null
//////////////////////////////////////////////////////////////////////////

  Void testReadNullType()
  {
    nil := Asn.Null
    verifyEq(Asn.Null, ber(enc(nil)).readObj)

    // verify get Any
    nil = Asn.Null.push(AsnTag.context(0).implicit)
    verify(ber(enc(nil)).readObj.isAny)

    // test with spec
    dec := ber(enc(nil)).readObj(nil)
    verify(dec.isNull)
    verifyEq(nil, dec)
  }

//////////////////////////////////////////////////////////////////////////
// Oid
//////////////////////////////////////////////////////////////////////////

  Void testReadOid()
  {
    verifyEq([1, 3,6, 0, 0xffffe], ber.readOid(octIn([43, 6, 0, 191, 255, 126])))
    verifyEq([0, 39], ber.readOid(octIn([39])))
    verifyEq([1, 39], ber.readOid(octIn([79])))
    verifyEq([2, 40], ber.readOid(octIn([120])))
    verifyEq([2, 0xffffffff], ber.readOid(octIn([0x90, 0x80, 0x80, 0x80, 0x4f])))
    verifyEq([2, 47], ber.readOid(octIn([0x7f])))
    verifyEq([2, 48], ber.readOid(octIn([0x81, 0x00])))
    verifyEq([2, 100, 3], ber.readOid(octIn([0x81, 0x34, 0x03])))
    verifyEq([2, 560], ber.readOid(octIn([133,0])))
    verifyEq([2, 16843570], ber.readOid(octIn([0x88, 0x84, 0x87, 0x02])))
  }

  Void testReadOidType()
  {
    o := Asn.oid("1.2.1024")
    verifyEq(o, ber(enc(o)).readObj)

    // verify get Any
    o = Asn.oid("2.3.2048").push(AsnTag.context(0).implicit)
    verify(ber(enc(o)).readObj.isAny)

    // test with spec
    verifyEq(o, ber(enc(o)).readObj(o))
  }

//////////////////////////////////////////////////////////////////////////
// Strings
//////////////////////////////////////////////////////////////////////////

  Void testStrings()
  {
    doStringTest(AsnTag.univUtf8)
    doStringTest(AsnTag.univPrintStr)
    doStringTest(AsnTag.univIa5Str)
    doStringTest(AsnTag.univVisStr)
  }

  private Void doStringTest(AsnTag univ)
  {
    str := Asn.str("", univ)
    verifyEq(str, ber(enc(str)).readObj)

    str = Asn.str("So many string types. Why?", univ)
    verifyEq(str, ber(enc(str)).readObj)

    // verify get Any
    str = str.push(AsnTag.context(0).implicit)
    verify(ber(enc(str)).readObj.isAny)

    // test with spec
    verifyEq(str, ber(enc(str)).readObj(str))
  }

//////////////////////////////////////////////////////////////////////////
// Timestamps
//////////////////////////////////////////////////////////////////////////

  Void testReadUtcTime()
  {
    // 2015-07-13 12:01:34 UTC
    verifyEq(DateTime(2015,Month.jul,13,12,01,34,0,TimeZone.utc),
             ber.readUtcTime(octIn([0x31,0x35,0x30,0x37,0x31,0x33,0x31,0x32,0x30,0x31,0x33,0x34,0x5A])))
    verifyEq(DateTime(1980,Month.feb,28,23,59,0,0,TimeZone.utc),
             ber.readUtcTime("8002282359Z".toBuf.in))
    verifyEq(DateTime(2000,Month.feb,28,23,59,59,0,TimeZone.utc),
             ber.readUtcTime("000228235959Z".toBuf.in))

    verifyEq(DateTime(2000,Month.jan,31,23,59,59,009_000_000,TimeZone.utc),
             ber.readUtcTime("000131235959.009Z".toBuf.in))
    verifyEq(DateTime(2000,Month.feb,28,23,59,59,090_000_000,TimeZone.utc),
             ber.readUtcTime("000228235959.09Z".toBuf.in))
    verifyEq(DateTime(2000,Month.dec,31,23,59,59,900_000_000,TimeZone.utc),
             ber.readUtcTime("001231235959.9Z".toBuf.in))
  }

  Void testReadUtcTimeType()
  {
    now := Asn.utc(DateTime.now.toUtc)
    verifyEq(now, ber(enc(now)).readObj)

    // verify get Any
    now = now.push(AsnTag.context(0).implicit)
    verify(ber(enc(now)).readObj.isAny)

    // test with spec
    verifyEq(now, ber(enc(now)).readObj(now))
  }

//////////////////////////////////////////////////////////////////////////
// testReadGenTime
//////////////////////////////////////////////////////////////////////////

  Void testReadGenTime()
  {
    // 2015-07-13 12:01:34 UTC
    verifyEq(DateTime(2015,Month.jul,13,12,01,34,0,TimeZone.utc),
             ber.readGenTime(octIn([0x32, 0x30, 0x31,0x35,0x30,0x37,0x31,0x33,0x31,0x32,0x30,0x31,0x33,0x34,0x5A])))
    verifyEq(DateTime(1980,Month.feb,28,23,59,0,0,TimeZone.utc),
             ber.readGenTime("198002282359Z".toBuf.in))
    verifyEq(DateTime(2000,Month.feb,28,23,59,59,0,TimeZone.utc),
             ber.readGenTime("20000228235959Z".toBuf.in))

    verifyEq(DateTime(2000,Month.jan,31,23,59,59,009_000_000,TimeZone.utc),
             ber.readGenTime("20000131235959.009Z".toBuf.in))
    verifyEq(DateTime(2000,Month.feb,28,23,59,59,090_000_000,TimeZone.utc),
             ber.readGenTime("20000228235959.09Z".toBuf.in))
    verifyEq(DateTime(2000,Month.dec,31,23,59,59,900_000_000,TimeZone.utc),
             ber.readGenTime("20001231235959.9Z".toBuf.in))
  }

  Void testReadGenTimeType()
  {
    now := Asn.genTime(DateTime.now)
    verifyEq(now, ber(enc(now)).readObj)

    // verify get Any
    now = now.push(AsnTag.context(0).implicit)
    verify(ber(enc(now)).readObj.isAny)

    // test with spec
    verifyEq(now, ber(enc(now)).readObj(now))
  }

//////////////////////////////////////////////////////////////////////////
// Sequence
//////////////////////////////////////////////////////////////////////////

  Void testReadSequenceType()
  {
    // empty
    seq  := Asn.seq([,])
    seq2 := Asn.seq([,])
    verify(ber(enc(seq)).readObj.coll.isEmpty)

    // one item
    one := Asn.int(1)
    seq  = Asn.seq([one])
    seq2 = (AsnColl)ber(enc(seq)).readObj
    verifyEq(1, seq2.size)
    verifyEq(one, seq2.get(0))

    // two items
    seq = Asn.seq([Asn.int(1), Asn.octets("two".toBuf)])
    b := BerWriter.toBuf(seq)
    seq2 = (AsnColl)ber(enc(seq)).readObj
    verifyEq(2, seq2.size)

    // nested
    oid := Asn.oid("1.2.3")
    seq = Asn.seq([Asn.seq([oid])])
    seq2 = (AsnColl)ber(enc(seq)).readObj
    nested := (AsnColl)seq2.vals.first
    verifyEq(oid, nested.vals.first)

    // verify get Any
    seq = Asn.seq([Asn.int(1)]).push(AsnTag.context(0).implicit)
    verify(ber(enc(seq)).readObj.isAny)

    // verify with spec
    verifyEq(seq, ber(enc(seq)).readObj(seq))
  }
}
