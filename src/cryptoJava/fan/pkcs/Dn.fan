//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using asn1

const class Dn
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a Dn from an a Str representation of a distinguished
  ** name. The distinguised name must be specified using the grammar
  ** defined in [RFC4514]`https://tools.ietf.org/html/rfc4514`.
  **
  static new fromStr(Str name)
  {
    return DnParser(name).dn
  }

  static new decode(Buf der)
  {
    fromSeq(BerReader(der.in).readObj)
  }

  static new fromSeq(AsnSeq rdnSeq)
  {
    rdns := Rdn[,]
    rdnSeq.vals.each |AsnSet set|
    {
      seq := (AsnSeq)set.vals.first
      rdns.add(Rdn(seq.vals[0], seq.vals[1]->val))
    }
    return Dn(rdns)
  }

  new make(Rdn[] rdns)
  {
    this.rdns  = rdns
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  const Rdn[] rdns

//////////////////////////////////////////////////////////////////////////
// Dn
//////////////////////////////////////////////////////////////////////////

  ** Get the `Rdn` at the index.
  @Operator
  Rdn get(Int index) { rdns[index] }

  AsnSeq asn()
  {
    items := AsnObj[,]
    rdns.each |Rdn rdn| { items.add(rdn.asn) }
    return Asn.seq(items)
  }
  
  override Str toStr()
  {
    buf := StrBuf()
    rdns.each |rdn, i|
    {
      if (i > 0) buf.addChar(',')
      buf.add(rdn.toStr)
    }
    return buf.toStr
  }

  **
  ** Return a normalized X.500 representation in standard order.
  ** Orders components as: C, ST/S, L, O, OU, CN, then any remaining.
  **
  ** Note: "S" components are automatically stored as "ST" (RFC 4514 standard).
  **
  Str toX500()
  {
    order := ["C":0, "ST":1, "S":1, "L":2, "O":3, "OU":4, "CN":5]
    
    x500 := rdns.dup.sort |a, b|
    {
      aName := a.shortName
      bName := b.shortName
      aPriority := aName == null ? 999 : order.get(aName, 999)
      bPriority := bName == null ? 999 : order.get(bName, 999)
      return aPriority <=> bPriority
    }
    
    return Dn(x500).toStr
  }
}
