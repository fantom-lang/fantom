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
  ** If 'checked' is true (default), parsing errors will throw an exception.
  ** If 'checked' is false, parsing errors will be caught and the raw string
  ** will be preserved, allowing the DN to be used even if it's malformed.
  **
  static new fromStr(Str name, Bool checked := true)
  {
    if (checked)
    {
      return DnParser(name).dn
    }
    else
    {
      try
      {
        return DnParser(name).dn
      }
      catch (Err e)
      {
        // Parsing failed - preserve raw string
        return Dn(Rdn#.emptyList, name)
      }
    }
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

  new make(Rdn[] rdns, Str? rawStr := null)
  {
    this.rdns = rdns
    this.rawStr = rawStr
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  const Rdn[] rdns
  
  ** 
  ** If parsing failed in unchecked mode, this contains the raw unparsed string.
  ** Otherwise null.
  **
  const Str? rawStr

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
  
  **
  ** Return a normalized string representation in standard X.500 order.
  ** Orders components as: C, ST/S, L, O, OU, CN, then any remaining.
  **
  ** Note: "S" components are automatically printed as "ST" (RFC 4514 standard).
  ** If parsing failed in unchecked mode, returns the raw unparsed string.
  **
  override Str toStr()
  {
    // If parsing failed in unchecked mode, return raw string
    if (rawStr != null) return rawStr
    
    // Define standard X.500 ordering
    order := ["C", "ST", "S", "L", "O", "OU", "CN"]
    
    // Collect RDNs in standard order
    normalized := Rdn[,]
    order.each |name|
    {
      rdns.each |rdn|
      {
        if (rdn.shortName == name && !normalized.contains(rdn))
          normalized.add(rdn)
      }
    }
    
    // Add any remaining RDNs not in standard order
    rdns.each |rdn|
    {
      if (!normalized.contains(rdn))
        normalized.add(rdn)
    }
    
    // Build normalized string - rdn.toStr() uses canonicalName which normalizes S to ST
    buf := StrBuf()
    normalized.each |rdn, i|
    {
      if (i > 0) buf.addChar(',')
      buf.add(rdn.toStr)
    }
    return buf.toStr
  }
}
