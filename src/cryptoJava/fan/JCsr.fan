//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using asn1
using crypto

const class JCsr : Csr
{
  new decode(Buf der)
  {
    req       := (AsnSeq)BerReader(der.in).readObj
    reqInfo   := (AsnSeq)req.vals[0]
    encPubKey := BerWriter.toBuf(reqInfo.vals[2])
    pubKey    := JPubKey.decode(encPubKey, "RSA")

    this.pub     = (PubKey)pubKey
    this.subject = Dn((AsnSeq)reqInfo.vals[1]).toStr
    this.sigAlg  = AlgId((req.vals[1] as AsnSeq).vals)
    this.opts    = ["algorithm": sigAlg.algorithm]
  }

  new make(KeyPair keys, Str subjectDn, Str:Obj opts)
  {
    this.pub     = keys.pub
    this.priv    = keys.priv
    this.subject = subjectDn
    this.opts    = opts
    this.sigAlg  = AlgId.fromOpts(opts)
  }

//////////////////////////////////////////////////////////////////////////
// Csr
//////////////////////////////////////////////////////////////////////////

  override const PubKey pub

  internal const PrivKey? priv := null

  override const Str subject

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
    // attrs  := Asn.tag(AsnTag.context(0).explicit).set([,])
    return Asn.seq([ver, name, pkInfo])
    // attrs  := Asn.tag(AsnTag.context(0).explicit).set([,])
    // return Asn.seq([ver, name, pkInfo, attrs])
  }

  private AsnObj sign(AsnSeq reqInfo)
  {
    Asn.bits(Pkcs1.sign(priv, BerWriter.toBuf(reqInfo), sigAlg))
  }
}
