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
using util

class JCertSigner : CertSigner
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(JCsr csr)
  {
    this.csr = csr
    this.subjectDn = Dn(csr.subject)

    // we start off as self-signed certificate
    this.caPrivKey = csr.priv
    this.issuerDn  = subjectDn
  }

  private const JCsr csr

  private PrivKey? caPrivKey
  private Dn subjectDn
  private Dn issuerDn
  private Int serialNumber := Random.makeSecure.next(0..<Int.maxVal)
  private DateTime _notBefore := Date.today.midnight
  private DateTime _notAfter  := (Date.today + 365day).midnight
  private AlgId sigAlg := AlgId(Pkcs1.sha256WithRSAEncryption)
  private AsnCollBuilder subjectAltNames := AsnColl.builder
  private V3Ext[] exts := [,]

//////////////////////////////////////////////////////////////////////////
// CertSigner
//////////////////////////////////////////////////////////////////////////

  override This ca(PrivKey caPrivKey, Cert caCert)
  {
    this.caPrivKey = caPrivKey
    this.issuerDn  = Dn(caCert.subject)
    return this
  }

  override This notBefore(Date date)
  {
    this._notBefore = date.midnight
    return this
  }

  override This notAfter(Date date)
  {
    this._notAfter = date.midnight
    return this
  }

  override This signWith(Str:Obj opts)
  {
    this.sigAlg = AlgId.fromOpts(opts)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Sign
//////////////////////////////////////////////////////////////////////////

  override Cert sign()
  {
    validate
    finish
    encoded := BerWriter.toBuf(asn)
    return X509.load(encoded.in).first
  }

  private Void validate()
  {
    if (caPrivKey == null)
      throw Err("No CA configured. The CSR must be generated with a KeyPair, or the ca() method must be called")

    // TODO: check duplicate V3Ext oid (not allowed by spec)
    if (_notBefore > _notAfter)
      throw Err("NotBefore ($_notBefore) is after NotAfter ($_notAfter)")
  }

  private Void finish()
  {
    // Add Subject Alternative Names V3 Ext
    sans := subjectAltNames.toSeq
    if (!sans.isEmpty)
    {
      this.exts.add(V3Ext(Asn.oid("2.5.29.17"), sans))
    }
  }

  // Certificate  ::=  SEQUENCE  {
  //      tbsCertificate       TBSCertificate,
  //      signatureAlgorithm   AlgorithmIdentifier,
  //      signatureValue       BIT STRING  }
  ** Generate the ASN for a signed certificate
  AsnSeq asn()
  {
    tbsCert := buildTbsCert
    signature := Asn.bits(Pkcs1.sign(caPrivKey, BerWriter.toBuf(tbsCert), sigAlg))
    return Asn.seq([tbsCert, sigAlg, signature])
  }

// TBSCertificate  ::=  SEQUENCE  {
//         version         [0]  EXPLICIT Version DEFAULT v1,
//         serialNumber         CertificateSerialNumber,
//         signature            AlgorithmIdentifier,
//         issuer               Name,
//         validity             Validity,
//         subject              Name,
//         subjectPublicKeyInfo SubjectPublicKeyInfo,
//         issuerUniqueID  [1]  IMPLICIT UniqueIdentifier OPTIONAL,
//                              -- If present, version MUST be v2 or v3
//         subjectUniqueID [2]  IMPLICIT UniqueIdentifier OPTIONAL,
//                              -- If present, version MUST be v2 or v3
//         extensions      [3]  EXPLICIT Extensions OPTIONAL
//                              -- If present, version MUST be v3
//         }
//
//    Version  ::=  INTEGER  {  v1(0), v2(1), v3(2)  }
//
//    CertificateSerialNumber  ::=  INTEGER
//
//    Validity ::= SEQUENCE {
//         notBefore      Time,
//         notAfter       Time }
//
//    Time ::= CHOICE {
//         utcTime        UTCTime,
//         generalTime    GeneralizedTime }
//
//    UniqueIdentifier  ::=  BIT STRING
//
//    SubjectPublicKeyInfo  ::=  SEQUENCE  {
//         algorithm            AlgorithmIdentifier,
//         subjectPublicKey     BIT STRING  }
//
//    Extensions  ::=  SEQUENCE SIZE (1..MAX) OF Extension
//
  ** Build TBSCertificate (see above)
  private AsnSeq buildTbsCert()
  {
    items := AsnObj[,]
      .add(Asn.tag(AsnTag.context(0).explicit).int(2))
      .add(Asn.int(serialNumber))
      .add(sigAlg)
      .add(issuerDn.asn)
      .add(Asn.seq([validity(_notBefore), validity(_notAfter)]))
      .add(subjectDn.asn)
      .add(Asn.any(csr.pub.encoded))
    if (!exts.isEmpty) items.add(Asn.tag(AsnTag.context(3).explicit).seq(exts))
    return Asn.seq(items)
  }

  ** https://datatracker.ietf.org/doc/html/rfc5280#section-4.1.2.5
  **
  ** CAs conforming to this profile MUST always encode certificate
  ** validity dates through the year 2049 as UTCTime; certificate validity
  ** dates in 2050 or later MUST be encoded as GeneralizedTime.
  ** Conforming applications MUST be able to process validity dates that
  ** are encoded in either UTCTime or GeneralizedTime.
  private static AsnObj validity(DateTime ts)
  {
    // force non-zero seconds because X509 requires them to be ASN.1 encoded
    if (ts.sec == 0) ts = ts + 1sec
    return ts.year < 2050 ? Asn.utc(ts.toUtc) : Asn.genTime(ts)
  }

//////////////////////////////////////////////////////////////////////////
// V3 Extensions
//////////////////////////////////////////////////////////////////////////

  override This subjectKeyId(Buf buf)
  {
    this.exts.add(V3Ext(Asn.oid("2.5.29.14"),
                         Asn.octets(buf)))
    return this
  }

  override This authKeyId(Buf buf)
  {
    this.exts.add(V3Ext(Asn.oid("2.5.29.35"),
                         Asn.seq([Asn.tag(AsnTag.context(0).implicit).octets(buf)])))
    return this
  }

  override This basicConstraints(Bool ca := false, Int? pathLenConstraint := null)
  {
    this.exts.add(BasicConstraints(ca, pathLenConstraint))
    return this
  }

  override This keyUsage(Buf bits)
  {
    this.exts.add(V3Ext(Asn.oid("2.5.29.15"),
                         Asn.bits(bits)))
    return this
  }

  override This subjectAltName(Obj name)
  {
    if (name is Str)
    {
      // dNSName [2] IA5String
      subjectAltNames.add(Asn.tag(AsnTag.context(2).implicit).str(name, AsnTag.univIa5Str))
    }
    else if (name is Uri)
    {
      // uniformResourceIdentifier [6] IA5String
      subjectAltNames.add(Asn.tag(AsnTag.context(6).implicit).str(name.toStr, AsnTag.univIa5Str))
    }
    else if (name is IpAddr)
    {
      // iPAddress [7] OCTET STRING
      subjectAltNames.add(Asn.tag(AsnTag.context(7).implicit).octets(((IpAddr)name).bytes))
    }
    else throw UnsupportedErr("Unsupported type for SAN: $name ($name.typeof)")
    return this
  }

  override This extendedKeyUsage(Str[] oids)
  {
    builder := AsnColl.builder
    oids.each |oid| { builder.add(Asn.oid(oid)) }
    this.exts.add(V3Ext(Asn.oid("2.5.29.37"),
                         builder.toSeq))
    return this
  }
}

**************************************************************************
** V3Ext
**************************************************************************

//    Extension  ::=  SEQUENCE  {
//         extnID      OBJECT IDENTIFIER,
//         critical    BOOLEAN DEFAULT FALSE,
//         extnValue   OCTET STRING
//                     -- contains the DER encoding of an ASN.1 value
//                     -- corresponding to the extension type identified
//                     -- by extnID
//         }
**
** V3Ext models an X.509 version 3 extension
**
@NoDoc
const class V3Ext : AsnSeq
{
  new makeSpec(AsnOid extnId, AsnObj val, Bool critical := false)
    : super.make([AsnTag.univSeq], AsnItem#.emptyList)
  {
    vals := AsnObj[extnId]
    if (critical) vals.add(Asn.bool(true))
    vals.add(Asn.octets(BerWriter.toBuf(val)))
    this.val = AsnColl.toItems(vals)
  }

  new make(AsnObj[] items) : super([AsnTag.univSeq], items)
  {
  }

  AsnOid extnId() { vals[0] }

  Bool isCritical()
  {
    vals[1].isBool ? vals[1].bool : false
  }

  Buf extnVal()
  {
    (vals[1].isOcts ? vals[1] : vals[2]).buf
  }
}

**************************************************************************
** BasicConstraints
**************************************************************************

// BasicConstraints ::= SEQUENCE {
//      cA                      BOOLEAN DEFAULT FALSE,
//      pathLenConstraint       INTEGER (0..MAX) OPTIONAL }
**
** Models a V3 extension BasicConstraints type.
**
@NoDoc
const class BasicConstraints : V3Ext
{
  static new basicConstraints(Bool isCa, Int? maxPathLen := null)
  {
    if (!isCa && maxPathLen != null) throw ArgErr("maxPathLen only valid if isCa is true")
    vals := AsnObj[,]
    if (isCa)
    {
      vals.add(Asn.bool(true))
      if (maxPathLen != null && maxPathLen < 0) throw ArgErr("Negative maxPathLen: ${maxPathLen}")
      if (maxPathLen != null) vals.add(Asn.int(maxPathLen))
    }
    return BasicConstraints(Asn.oid("2.5.29.19"), Asn.seq(vals))
  }

  new makeSpec(AsnOid extnId, AsnColl extnVal, Bool critical := false)
    : super.makeSpec(extnId, extnVal, critical)
  {
  }

  new make(AsnObj[] items) : super(items)
  {
  }

  Bool isCa()
  {
    if (isEmpty) return false
    return vals[0].isBool ? vals[0].bool : false
  }

  Int? maxPath()
  {
    if (isEmpty) return null
    if (vals[0].isInt) return vals[0].int
    return vals.getSafe(1)?.int
  }
}