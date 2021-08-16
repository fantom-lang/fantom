//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 2021 Matthew Giannini Creation
//

using math

class AsnObjTest : Test
{
  private static const AsnTag cx1 := AsnTag.context(1).implicit
  private static const AsnTag cx2 := AsnTag.context(2).implicit

  Void testBoolean()
  {
    verifyEq(AsnTag.univBool.id, 1)
    verifyEq(Asn.bool(true), Asn.bool(true))
    verifyEq(Asn.bool(false), Asn.bool(false))
    verifyNotEq(Asn.bool(true), Asn.bool(false))
    verifyNotEq(Asn.bool(true), Asn.tag(cx1).bool(true))
  }

  Void testInteger()
  {
    verifyEq(AsnTag.univInt.id, 2)
    t := AsnTag.univInt
    verifyEq(Asn.int(0), Asn.int(0))
    verifyEq(Asn.tag(cx2).int(0),
             Asn.tag(cx2).int(0))
    verifyEq(Asn.int(123), Asn.int(BigInt.fromStr("123")))
    verifyNotEq(Asn.int(0), Asn.int(1))
    verifyNotEq(Asn.int(0), Asn.tag(cx2).int(0))
    verifyNotEq(Asn.int(0).push(AsnTag.context(2).explicit),
                Asn.int(0).push(cx2))
  }

  Void testOctetString()
  {
    verifyEq(AsnTag.univOcts.id, 4)
    a := Asn.octets("foo".toBuf)
    verifyEq(a, a)
    b := Asn.octets("foo".toBuf)
    verifyEq(a, b)
    verifyNotEq(a, Asn.octets("fooo".toBuf))
    verifyNotEq(a, a.push(AsnTag.context(4).implicit))
 }

  Void testBitString()
  {
    verifyEq(AsnTag.univBits.id, 3)
    a := Asn.bits(Buf.fromHex("cafe_babe"))
    verifyEq(a, a)
    b := Asn.bits(Buf.fromHex("cafe_babe"))
    verifyEq(a, b)
    verifyNotEq(a, Asn.bits(Buf.fromHex("dead_beef")))
    verifyNotEq(a, a.push(AsnTag.context(3).implicit))
  }

  Void testOid()
  {
    verifyEq(AsnTag.univOid.id, 6)
    ctag := AsnTag.context(0).implicit
    a := Asn.oid("0.1")
    verifyEq(a,a)
    verifyNotEq(a, a.push(ctag))

    b := Asn.oid("0.1")
    verifyEq(a,b)

    verifyEq(Asn.oid([0,1]), Asn.oid("0.1"))

    verifyNotEq(a, Asn.oid("1.1"))

    verifyNotEq(Asn.oid("2.100"), Asn.oid("2.100").push(ctag))
  }

  Void testOidCompare()
  {
    a := Asn.oid("0")
    b := Asn.oid("0")
    verify((a <=> b) == 0)

    b = Asn.oid("0.1")
    verify((a <=> b) < 0)
    verify((b <=> a) > 0)

    a = Asn.oid("1.2.3.4")
    b = Asn.oid("1.200.3")
    verify((a <=> b) < 0)
    verify((b <=> a) > 0)
  }

  Void testOidGetRange()
  {
    a := Asn.oid("1")
    verifyEq(a, a[0..-1])
    verifyErr(IndexErr#) { b := a[0..1] }

    a = Asn.oid("1.2.3.4.5")
    verifyEq(a, a[0..-1])
    verifyEq(Asn.oid("1.2.3"), a[0..<3])
    verifyEq(Asn.oid("2.3.4"), a[1..<4])
  }

  Void testNull()
  {
    verifyEq(AsnTag.univNull.id, 5)
    verifyEq(Asn.Null, Asn.Null)
    verifyNotEq(Asn.Null, Asn.Null.push(AsnTag.context(5).implicit))
  }

  Void testIA5Str()
  {
    verifyEq(AsnTag.univIa5Str.id, 22)
    a := Asn.str("foo", AsnTag.univIa5Str)
    b := Asn.str("foo", AsnTag.univIa5Str)
    verifyEq(a, b)
    verifyNotEq(a, Asn.str("bar", AsnTag.univIa5Str))
    verifyNotEq(a, b.push(AsnTag.context(22).implicit))
  }

  Void testPrintableStr()
  {
    t := AsnTag.univPrintStr
    verifyEq(t.id, 19)
    a := Asn.str("foo", t)
    b := Asn.str("foo", t)
    verifyEq(a, b)
    verifyNotEq(a, Asn.str("bar", t))
    verifyNotEq(a, b.push(AsnTag.context(19).implicit))
  }

  Void testUtf8Str()
  {
    verifyEq(AsnTag.univUtf8.id, 12)
    a := Asn.utf8("αγαπη")
    b := Asn.utf8("αγαπη")
    verifyEq(a, b)
    verifyNotEq(a, Asn.utf8("φιλος"))
    verifyNotEq(a, b.push(AsnTag.context(12).implicit))
  }

  Void testVisibleStr()
  {
    t := AsnTag.univVisStr
    verifyEq(t.id, 26)
    a := Asn.str("foo", t)
    b := Asn.str("foo", t)
    verifyEq(a, b)
    verifyNotEq(a, Asn.str("bar", t))
    verifyNotEq(a, b.push(AsnTag.context(t.id).implicit))
  }

  Void testUtcTime()
  {
    verifyEq(AsnTag.univUtcTime.id, 23)
    ts1 := Date.fromStr("2015-03-24").midnight
    ts2 := ts1 - 1day
    verifyEq(Asn.utc(ts1), Asn.utc(ts1))
    verifyNotEq(Asn.utc(ts1), Asn.utc(ts2))
    verifyNotEq(Asn.utc(ts1), Asn.utc(ts1).push(AsnTag.context(23).implicit))
  }

  Void testGenTime()
  {
    verifyEq(AsnTag.univGenTime.id, 24)
    ts1 := Date.fromStr("2015-03-24").midnight
    ts2 := ts1 - 1day
    verifyEq(Asn.genTime(ts1), Asn.genTime(ts1))
    verifyNotEq(Asn.genTime(ts1), Asn.genTime(ts2))
    verifyNotEq(Asn.genTime(ts1), Asn.genTime(ts1).push(AsnTag.context(24).implicit))
  }

  Void testSequence()
  {
    verifyEq(AsnTag.univSeq.id, 16)
    ctag := AsnTag.context(16).implicit
    a := Asn.seq([,])
    verifyEq(a, a)

    b := Asn.seq([,])
    verifyEq(a, b)

    verifyEq(Asn.seq([Asn.int(1)]), Asn.seq([Asn.int(1)]))

    i := Asn.int(1)
    s := Asn.octets("octets".toBuf)
    o := Asn.oid("1.2.3.4.5")
    seq := Asn.seq([o,s,i])
    verifyEq(seq, seq)
    verifyNotEq(seq, Asn.tag(ctag).seq([o,s,i]))

    verifyEq(Asn.seq([i,s,o]), Asn.seq([i,s,o]))
    verifyEq(Asn.seq([seq]), Asn.seq([Asn.seq([o,s,i])]))
    verifyEq(Asn.seq([Asn.Null, seq]), Asn.seq([Asn.Null, seq]))
    verifyNotEq(Asn.seq([,]), Asn.seq([i]))
    verifyNotEq(Asn.seq([i,s,o]), seq)

    // bigger seq of seqs
    s1 := Asn.seq([Asn.seq([Asn.int(1)])])
    s2 := Asn.seq([Asn.seq([Asn.int(1)])])
    s3 := Asn.seq([Asn.seq([Asn.int(1), Asn.int(2)])])
    verifyEq(s1,s2)
    verifyNotEq(s1,s3)
  }
}