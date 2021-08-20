//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using crypto
using asn1

**
** See [RFC 3447 (PKCS #1: RSA Cryptography Specifications Version 2.1)]`https://tools.ietf.org/html/rfc3447`
** See [RSA Cryptography Standard v2.2]`http://www.emc.com/emc-plus/rsa-labs/pkcs/files/h11300-wp-pkcs-1v2-2-rsa-cryptography-standard.pdf`
**
const mixin Pkcs1
{
  const static AsnOid pkcs_1 := Asn.oid("1.2.840.113549.1.1")

  ** When rsaEncryption is used in an AlgorithmIdentifier the
  ** parameters MUST be present and MUST be NULL.
  const static AsnOid rsaEncryption := Asn.oid("${pkcs_1.oidStr}.1")

  // When the following OIDs are used in an AlgorithmIdentifier the
  // parameters MUST be present and MUST be NULL.
  const static AsnOid sha1WithRSAEncryption   := Asn.oid("${pkcs_1.oidStr}.5")
  const static AsnOid sha256WithRSAEncryption := Asn.oid("${pkcs_1.oidStr}.11")
  const static AsnOid sha384WithRSAEncryption := Asn.oid("${pkcs_1.oidStr}.12")
  const static AsnOid sha512WithRSAEncryption := Asn.oid("${pkcs_1.oidStr}.13")

  static Buf sign(PrivKey key, Buf data, AlgId sigAlg)
  {
    digest := (Str?)null
    switch (sigAlg.id)
    {
      case sha1WithRSAEncryption:   digest = "SHA1"
      case sha256WithRSAEncryption: digest = "SHA256"
      case sha384WithRSAEncryption: digest = "SHA384"
      case sha512WithRSAEncryption: digest = "SHA512"
      default: throw ArgErr("Unsupported algorithm id: ${sigAlg.id}")
    }
    return key.sign(data, digest)
  }
}

**
** Algorithm-Identifier
**
const class AlgId : AsnSeq
{
  static new fromOpts(Str:Obj opts)
  {
    optAlg := opts["algorithm"] ?: "sha256WithRSAEncryption"
    switch(optAlg)
    {
      case "sha256WithRSAEncryption": return AlgId(Pkcs1.sha256WithRSAEncryption)
      case "sha384WithRSAEncryption": return AlgId(Pkcs1.sha384WithRSAEncryption)
      case "sha512WithRSAEncryption": return AlgId(Pkcs1.sha512WithRSAEncryption)
      default: throw UnsupportedErr("Unsupported PKCS1 signature algorithm: $optAlg")
    }
  }

  new makeSpec(AsnOid algorithm, AsnObj? parameters := Asn.Null)
    : super.make([AsnTag.univSeq], AsnItem#.emptyList)
  {
    vals := AsnObj[algorithm]
    if (parameters != null) vals.add(parameters)
    this.val = AsnColl.toItems(vals)
  }

  new make(AsnObj[] items) : super([AsnTag.univSeq], items)
  {
  }

  AsnOid id() { vals[0] }

  AsnObj? params() { vals.getSafe(1) }

  Str algorithm()
  {
    Pkcs1#.fields.find { it.get == this.id }.name
  }
}

