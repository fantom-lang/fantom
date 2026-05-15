//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using asn1
using crypto
using inet

const class JCsr : Csr
{
  new decode(Buf der)
  {
    req       := (AsnSeq)BerReader(der.in).readObj
    reqInfo   := (AsnSeq)req.vals[0]
    encPubKey := BerWriter.toBuf(reqInfo.vals[2])
    pubKey    := JPubKey.decode(encPubKey, "RSA")

    this.pub     = (PubKey)pubKey
    this.subject = Dn((AsnSeq)reqInfo.vals[1]).toX500
    this.sigAlg  = AlgId((req.vals[1] as AsnSeq).vals)
    this.opts    = ["algorithm": sigAlg.algorithm]
    this.subjectAltNames = decodeSansFromReqInfo(reqInfo)
  }

  new make(KeyPair keys, Str subjectDn, Str:Obj opts)
  {
    this.pub     = keys.pub
    this.priv    = keys.priv
    this.subject = Dn.fromStr(subjectDn).toX500
    this.sigAlg  = AlgId.fromOpts(opts)
    this.opts = opts.ro

    optsSanList := opts["subjectAltNames"] as List
    if (optsSanList != null && !optsSanList.isEmpty)
    {
      builder := AsnColl.builder
      sanList := San[,]
      optsSanList.each |name|
      {
        try
        {
          jSan := San.fromValue(name)
          SubjectAltNames.encodeName(jSan, builder)
          sanList.add(jSan)
        }
        catch (Err e) { } //Skip names that cannot be parsed
      }
      this.san = builder.toSeq
      this.subjectAltNames = sanList
    }
    else
    {
      this.subjectAltNames = San[,]
    }

  }

//////////////////////////////////////////////////////////////////////////
// Csr
//////////////////////////////////////////////////////////////////////////

  override const PubKey pub

  internal const PrivKey? priv := null

  override const Str subject

  override const San[] subjectAltNames

  private const AsnSeq? san

  override const Str:Obj opts := [:]

  private const AlgId sigAlg

  Str pem()
  {
    buf := Buf()
    gen(buf.out)
    return buf.flip.readAllStr
  }

  override Str toStr()
  {
    if (priv != null) return pem
    return "CSR for $subject"
  }

//////////////////////////////////////////////////////////////////////////
// Generate
//////////////////////////////////////////////////////////////////////////

  Void gen(OutStream out, Bool close := true)
  {
    if (priv == null) throw ArgErr("No private key was supplied")
    PemWriter(out).write(PemLabel.csr, BerWriter.toBuf(asn))
    if (close) out.close
  }

  AsnSeq asn()
  {
    reqInfo := buildReqInfo
    sig     := sign(reqInfo)
    return Asn.seq([reqInfo, sigAlg, sig])
  }

  private AsnSeq buildReqInfo()
  {
    ver    := Asn.int(0)
    name   := Dn(subject).asn
    pkInfo := Asn.any(pub.encoded)
    attrs  := buildAttributes
    return Asn.seq([ver, name, pkInfo, attrs])
  }

  ** Build CSR attributes section (RFC 2986)
  ** Attributes ::= SET OF Attribute
  private AsnObj buildAttributes()
  {
    attrList := AsnObj[,]

    if (san != null)
    {
      sanExt := SubjectAltNames.makeExt(san)

      // Build extensionRequest attribute
      // Attribute ::= SEQUENCE {
      //   type  OBJECT IDENTIFIER (1.2.840.113549.1.9.14),
      //   values SET OF Extensions
      // }
      extensionReq := Asn.seq([
        Asn.oid("1.2.840.113549.1.9.14"),  // extensionRequest OID
        Asn.set([Asn.seq([sanExt])])       // SET OF Extensions
      ])

      attrList.add(extensionReq)
    }

    // Create the SET first, then push the implicit context tag
    attrs := Asn.set(attrList)
    return attrs.push(AsnTag.context(0).implicit)
  }

  private AsnObj sign(AsnSeq reqInfo)
  {
    Asn.bits(Pkcs1.sign(priv, BerWriter.toBuf(reqInfo), sigAlg))
  }

  ** Decode Subject Alternative Names from CSR attributes (RFC 2986)
  private static San[] decodeSansFromReqInfo(AsnSeq reqInfo)
  {
    try
    {
      if (reqInfo.vals.size < 4) return Obj[,]

      attrsObj := reqInfo.vals[3]
      if (!attrsObj.tag.cls.isContext || attrsObj.tag.id != 0) return Obj[,]

      // Get the SET OF Attribute
      attrsColl := attrsObj
      if (attrsObj is AsnBin)
      {
        // Decode the binary content as a SET
        decoded := ((AsnBin)attrsObj).decode(Asn.set([,]))
        attrsColl = decoded
      }

      if (attrsColl isnot AsnColl) return Obj[,]
      attrs := ((AsnColl)attrsColl).vals
      // Look for extensionRequest attribute (OID 1.2.840.113549.1.9.14)
      extReqOid := "1.2.840.113549.1.9.14"

      // Search through attributes
      for (i := 0; i < attrs.size; ++i)
      {
        attr := attrs[i]
        if (attr isnot AsnSeq) continue

        attrSeq := (AsnSeq)attr
        if (attrSeq.vals.size < 2) continue

        oid := attrSeq.vals[0]
        if (oid isnot AsnOid) continue
        if (((AsnOid)oid).oidStr != extReqOid) continue

        // Found extensionRequest, extract extensions
        // vals[1] is a SET containing a SEQUENCE of extensions
        if (attrSeq.vals[1] isnot AsnColl) continue
        valuesSet := ((AsnColl)attrSeq.vals[1]).vals
        if (valuesSet.isEmpty) continue
        if (valuesSet[0] isnot AsnSeq) continue

        extsSeq := ((AsnSeq)valuesSet[0]).vals

        // Look for SubjectAltName extension (OID 2.5.29.17)
        for (j := 0; j < extsSeq.size; ++j)
        {
          ext := extsSeq[j]
          if (ext isnot AsnSeq) continue

          extSeq := (AsnSeq)ext
          if (extSeq.vals.size < 2) continue

          extOid := extSeq.vals[0]
          if (extOid isnot AsnOid) continue
          if (((AsnOid)extOid).oidStr != "2.5.29.17") continue

          // Found SAN extension
          // Extract the extnValue (OCTET STRING containing DER-encoded GeneralNames)
          // It's either vals[1] (no critical flag) or vals[2] (with critical flag)
          octets := extSeq.vals[1]
          if (!octets.isOcts && extSeq.vals.size >= 3)
            octets = extSeq.vals[2]

          if (octets.isOcts)
          {
            // Decode the OCTET STRING to get the GeneralNames sequence
            generalNames := BerReader(octets.buf.in).readObj as AsnSeq
            return SubjectAltNames.decodeNames(generalNames)
          }
        }
      }
    }
    // If parsing fails, just return empty list rather than failing the whole decode
    catch (Err e) {}

    return Obj[,]
  }
}
