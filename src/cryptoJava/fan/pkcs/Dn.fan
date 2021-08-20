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
  ** Create a Dn from an a Str representation of an X.500 distinguished
  ** name. The distinguised name must be specified using the grammar
  ** defined in [RFC4514]`https://tools.ietf.org/html/rfc4514`.
  **
  static new fromStr(Str name)
  {
    DnParser(name).dn
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
    this.rdns = rdns
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
}