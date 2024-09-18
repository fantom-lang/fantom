// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//   12 Sep 2024 Ross Schwalm       Add support for EC Private Keys encoded as specified in SEC 1
//

using asn1

**************************************************************************
** PemConst
**************************************************************************

mixin PemConst
{
  static const Str DASH5    := "-----"
  static const Str BEGIN    := "${DASH5}BEGIN "
  static const Str END      := "${DASH5}END "
  static const Int pemChars := 64
}

**************************************************************************
** PemLabel
**************************************************************************

enum class PemLabel
{
  publicKey("PUBLIC KEY"),
  rsaPrivKey("RSA PRIVATE KEY"),
  ecPrivKey("EC PRIVATE KEY"),
  privKey("PRIVATE KEY"),
  cert("CERTIFICATE"),
  csr("CERTIFICATE REQUEST")

  private new make(Str text)
  {
    this.text = text
  }

  static PemLabel? find(Str text)
  {
    vals.find { it.text == text }
  }

  const Str text
}

**************************************************************************
** PemWriter
**************************************************************************

class PemWriter : PemConst
{
  new make(OutStream out)
  {
    this.out = out
  }

  This write(PemLabel label, Buf der)
  {
    base64 := der.toBase64
    size   := base64.size
    idx    := 0
    out.writeChars("${BEGIN}${label.text}${DASH5}\n")
    while (idx < size)
    {
      end := (idx + pemChars).min(size)
      out.writeChars(base64[idx..<end]).writeChar('\n')
      idx += pemChars
    }
    out.writeChars("${END}${label.text}${DASH5}\n")
    return this
  }

  ** Convenience to close the out stream
  Void close() { out.close }

  OutStream out { private set }
}

**************************************************************************
** PemReader
**************************************************************************

class PemReader : PemConst
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(InStream in, Str algorithm)
  {
    this.in = in
    this.algorithm = algorithm
  }

  Obj? next()
  {
    if (!skipToBegin) { in.close; return null }
    parseLabel
    base64 := parseBase64
    der := Buf.fromBase64(base64)
    switch (PemLabel.find(label))
    {
      case PemLabel.rsaPrivKey:
        der = Buf.fromBase64(rsaP1ToP8(base64))
        return JPrivKey.decode(der, "RSA")
      case PemLabel.ecPrivKey:
        der = Buf.fromBase64(ecSEC1ToP8(base64))
        return JPrivKey.decode(der, "EC")
      case PemLabel.privKey:
        return JPrivKey.decode(der, algorithm)
      case PemLabel.publicKey:
        return JPubKey.decode(der, algorithm)
      case PemLabel.cert:
        return X509.load(der.in).first
      case PemLabel.csr:
        return JCsr.decode(Buf.fromBase64(base64))
    }
    throw ParseErr("Unsupported label: ${label}")
  }

  private Bool skipToBegin()
  {
    while (nextLine != null)
    {
      if (line.startsWith(BEGIN) && line.endsWith(DASH5)) return true
    }
    return false
  }

  private Str parseLabel()
  {
    this.label = line[(BEGIN.size)..<(line.size-DASH5.size)]
  }

  private Str parseBase64()
  {
    end    := "${END}${label}${DASH5}"
    base64 := StrBuf()
    while (true)
    {
      nextLine
      if (line == null) throw ParseErr("Unexpected end-of-file")
      if (line == end) break
      base64.add(line)
    }
    return base64.toStr
  }

  private Str rsaP1ToP8(Str base64)
  {
    p1 := Buf.fromBase64(base64)
    AsnOid oid := BerReader(Buf.fromHex("06092A864886F70D010101").in).readObj
    root := Asn.seq([
      Asn.int(0),
      Asn.seq([
        oid,
        Asn.Null]),
      Asn.octets(p1)])
    return BerWriter.toBuf(root).toBase64
  }

  ** Converts EC Private Key ASN.1 encoding format defined in [SEC 1]`https://www.secg.org/sec1-v2.pdf`
  ** as well as [RFC5915]`https://www.rfc-editor.org/rfc/rfc5915` to PKCS#8
  **
  ** ECPrivateKey ::= SEQUENCE {
  **   version INTEGER { ecPrivkeyVer1(1) } (ecPrivkeyVer1),
  **   privateKey OCTET STRING,
  **   parameters [0] ECParameters {{ NamedCurve }} OPTIONAL,
  **   publicKey  [1] BIT STRING OPTIONAL
  ** }
  **
  ** ECParameters format is defined in [RFC5480]`https://www.rfc-editor.org/rfc/rfc5480`
  **
  ** ECParameters ::= CHOICE {
  **   namedCurve         OBJECT IDENTIFIER
  **   -- implicitCurve   NULL
  **   -- specifiedCurve  SpecifiedECDomain
  ** }
  private Str ecSEC1ToP8(Str base64)
  {
    sec1 := Buf.fromBase64(base64)
    seq := BerReader(sec1.in).readObj
    parts := seq.val as List

    // Only support importing keys that include the optional ECParameters
    if (parts.size < 3) throw ArgErr("Invalid EC Private Key Encoding")

    ecParams := (((AsnItem)parts[2]).val as AsnObj)

    AsnTag cx0 := AsnTag.context(0).implicit
    if (ecParams.tags[0] != cx0) throw ArgErr("Invalid EC Private Key ECParameters")

    AsnOid oid := Asn.oid("1.2.840.10045.2.1") //id-ecPublicKey
    AsnOid curve := BerReader(Buf.fromHex(ecParams.buf.toHex).in).readObj

    root := Asn.seq([
      Asn.int(0),
      Asn.seq([
        oid,
        curve]),
      Asn.octets(sec1)])

    return BerWriter.toBuf(root).toBase64
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  private Str? nextLine()
  {
    this.line = in.readLine
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str algorithm   // only for PKCS8

  private InStream in
  private Str? line
  private Str? label
}
