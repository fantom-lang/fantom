//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

class AsnTagTest : Test
{
  Void testEquality()
  {
    e := AsnTag.univ(0).explicit
    verifyEq(e, AsnTag.univ(0).explicit)
    verifyNotEq(e, AsnTag.univ(1).explicit)
    // verifyNotEq(e, AsnTag.implicit(TagClass.univ, 0))

    c := AsnTag.context(0).implicit
    verifyEq(c, AsnTag.context(0).implicit)
    verifyNotEq(c, AsnTag.context(1).implicit)
    // verifyNotEq(c, AsnTag.explicit(TagClass.context, 0))
  }

  ** Page 244 (12.1.4) Dubuisson - ASN.1 Communication between Heterogeneous Systems
  Void testEffectiveTags()
  {
    // T ::= [1] IMPLICIT [0] EXPLICIT BOOLEAN => [1] [UNIVERAL 1]
    o1 := Asn.bool(true)
      .push(AsnTag.context(0).explicit)
      .push(AsnTag.context(1).implicit)
    verifyEq(o1.effectiveTags,
             AsnTag[AsnTag.context(1).explicit, AsnTag.univBool])

    // T ::= [1] EXPLICIT [0] IMPLICIT BOOLEAN => [1] [0]
    o2 := Asn.bool(true)
      .push(AsnTag.context(0).implicit)
      .push(AsnTag.context(1).explicit)
    verifyEq(o2.effectiveTags,
             AsnTag[AsnTag.context(1).explicit, AsnTag.context(0).explicit])

  }
}