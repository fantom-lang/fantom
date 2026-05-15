//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Apr 2026 Ross Schwalm   Creation
//

using crypto
using asn1
using inet

**
** Test cases for Certificate Signing Request (CSR) functionality
**
class JCsrTest : CryptoTest
{

  Void testCsrWithDnsSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "cn=example.com,o=Example Corp"

    sans := ["example.com", "www.example.com", "api.example.com", San.dnsName("fantom.org")]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, "O=Example Corp,CN=example.com")
    verifyNotNull(csr.opts)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    verifyTrue(csr.subjectAltNames.size == 4)
    verifyEq(((San)csr.subjectAltNames[0]).type, SanType.dnsName)
    verifyEq(((San)csr.subjectAltNames[0]).val, "example.com")
    verifyEq(((San)csr.subjectAltNames[1]).type, SanType.dnsName)
    verifyEq(((San)csr.subjectAltNames[1]).val, "www.example.com")
    verifyEq(((San)csr.subjectAltNames[2]).type, SanType.dnsName)
    verifyEq(((San)csr.subjectAltNames[2]).val, "api.example.com")
    verifyEq(((San)csr.subjectAltNames[3]).type, SanType.dnsName)
    verifyEq(((San)csr.subjectAltNames[3]).val, "fantom.org")
  }

  Void testCsrWithIpSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[IpAddr("192.168.1.100"), IpAddr("10.0.0.50"), San.ipAddr("10.0.0.1")]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    verifyTrue(csr.subjectAltNames.size == 3)
    verifyEq(((San)csr.subjectAltNames[0]).type, SanType.ipAddr)
    verifyEq(((San)csr.subjectAltNames[0]).val, IpAddr("192.168.1.100"))
    verifyEq(((San)csr.subjectAltNames[1]).type, SanType.ipAddr)
    verifyEq(((San)csr.subjectAltNames[1]).val, IpAddr("10.0.0.50"))
    verifyEq(((San)csr.subjectAltNames[2]).type, SanType.ipAddr)
    verifyEq(((San)csr.subjectAltNames[2]).val, IpAddr("10.0.0.1"))
  }

  Void testCsrWithUriSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[
      `https://api.example.com`,
      `https://api-v2.example.com`,
      San.uri("https://internal.example.com")
    ]

    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)
    verifyNotNull(csr.toStr)
    verifyTrue(csr.subjectAltNames.size == 3)
    verifyEq(((San)csr.subjectAltNames[0]).type, SanType.uri)
    verifyEq(((San)csr.subjectAltNames[0]).val, "https://api.example.com/")
    verifyEq(((San)csr.subjectAltNames[1]).type, SanType.uri)
    verifyEq(((San)csr.subjectAltNames[1]).val, "https://api-v2.example.com/")
    verifyEq(((San)csr.subjectAltNames[2]).type, SanType.uri)
    verifyEq(((San)csr.subjectAltNames[2]).val, "https://internal.example.com")

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
  }

  Void testCsrWithRFC822San()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[San.rfc822Name("user@fantom.org")]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    decodedSans := decodedCsr.subjectAltNames
    verifyEq(decodedSans.size, 1)
    verifyEq(((San)decodedSans[0]).type, SanType.rfc822Name)
    verifyEq(((San)decodedSans[0]).val, "user@fantom.org")
  }

  Void testCsrWithRegisteredIdSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[San.registeredId("1.2.3.4.5.6")]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    decodedSans := decodedCsr.subjectAltNames
    verifyEq(decodedSans.size, 1)
    verifyEq(((San)decodedSans[0]).type, SanType.registeredId)
    verifyEq(((San)decodedSans[0]).val, "1.2.3.4.5.6")
  }

  Void testCsrWithDirNameSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Test"

    sanDn := "C=US,O=Fantom,OU=Sales,CN=alt-dir-name"

    sans := Obj[San.dirName(sanDn)]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    decodedSans := decodedCsr.subjectAltNames
    verifyEq(decodedSans.size, 1)

    verifyEq(((San)decodedSans[0]).type, SanType.dirName)
    verifyEq(((San)decodedSans[0]).toStr, "dirName:$sanDn")
    verifyEq(((San)decodedSans[0]).val, sanDn)
  }

  Void testCsrWithMixedSans()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[
      "test.example.com",
      "www.test.example.com",
      `https://test.example.com`,
      IpAddr("192.168.1.1"),
      IpAddr("10.0.0.1")
    ]

    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
    verifyEq(decodedCsr.subject, "CN=Fantom")
    Obj[] values := decodedCsr.subjectAltNames.mapNotNull |san| { san.val }
    verifyEq(values, Obj[
                      "test.example.com",
                      "www.test.example.com",
                      "https://test.example.com/",
                      IpAddr("192.168.1.1"),
                      IpAddr("10.0.0.1")])
  }

  Void testOpensslCsr()
  {
    openssl := Str<|-----BEGIN CERTIFICATE REQUEST-----
                    MIIC1jCCAb4CAQAwUzELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAlZBMREwDwYDVQQH
                    DAhSaWNobW9uZDEPMA0GA1UECgwGRmFudG9tMRMwEQYDVQQDDApmYW50b20ub3Jn
                    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuj4CHcCSOWo0T7l3L6E+
                    +fld2i6jkGfFNlajDlGR10rHuOrkTxaMbz9JTxrQIPQEYz8ewDskXPsqD5j17nNs
                    xrG/pMGB6gspBJeVFWIvKyxHfzKvZ8YN4h1BM/8shRwrENhB5LxEerai68/l78az
                    IsBq+w8AUV3H8MSo3tqhGR9eihlkb66XEXbmpJ3p8sB2Mskr5z4IUAqiWPLy30/H
                    6+yZfQuWAQci7KT1m8/DHpDo0vu6y7SZlNwW15WOZtoZBZiNpkahjSlk2s3OCrk4
                    5ql6zDH6zdSvQ2unS4VinEaCGRkkVVFS0qTQd/3tkEHgLggkiNKDyAV9cqE5QGP9
                    owIDAQABoD4wPAYJKoZIhvcNAQkOMS8wLTArBgNVHREEJDAiggpmYW50b20ub3Jn
                    gg53d3cuZmFudG9tLm9yZ4cEwKgBATANBgkqhkiG9w0BAQsFAAOCAQEAkDBjSBaj
                    Pc8MvJjXGPLwWChWGBcXYxIlAtKYtE/oZ+qmssFaBKHzMb5p6nO+LpL7OtPy7/Qu
                    /XqhIVa+PGkCaifNOG7WH7V80Y6wD5Ek87uFcsra1J40fX76+Mqh85oLBtMefxsC
                    76W8N+5svOI8xWLzyDs6Wpnm6iIWhSVHz/XYo/hxB1s/Z8rvXwFBquiiBwoYHM5j
                    nyC8767OMG6RQ5QBHhiZ5RUEDe2DxRlf19cjYyW+UNLoGaINdTP5YLylSO2ZHxG2
                    6M93q+wCZ8qJk5TgPEYWXp2HJfqTfMJVGwCKqlZ3OHmAwTMLAkVGyT2C0YBm55XX
                    sAH0mg+4tWQndw==
                    -----END CERTIFICATE REQUEST-----|>

    decodedCsr := crypto.loadPem(openssl.in) as Csr
    verifyNotNull(decodedCsr)
    verifyEq(decodedCsr.subject, "C=US,ST=VA,L=Richmond,O=Fantom,CN=fantom.org")

    sans := decodedCsr.subjectAltNames
    verifyEq(sans.size, 3)

    Obj[] values := sans.mapNotNull |san| { san.val }
    verifyEq(values, Obj["fantom.org", "www.fantom.org", IpAddr("192.168.1.1")])
  }

  Void testCsrSanToSignedCert()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := ["san-test.fantom.org",
             San.dnsName("www.san-test.fantom.org"),
             IpAddr("192.168.1.1"),
             San.ipAddr("192.168.1.2"),
             San.rfc822Name("user@fantom.org"),
             `https://fantom.org/doc`,
             San.uri("https://fantom.org"),
             Asn.oid("1.2.840.113549.1.9.1"), //emailAddress OID
             San.registeredId("1.2.840.113549.1.9.1"),
             San.dirName("C=US,CN=Test")
             ]

    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    cert := crypto.certSigner(csr)
              .notBefore(Date.today)
              .notAfter(Date.today + 90day)
              .sign

    verifyNotNull(cert)
    verifyEq(cert.subject, "CN=Fantom")
    certSans := cert.subjectAltNames

    verifyEq(certSans.size, 10)
    verifyEq(((San)certSans[0]).type, SanType.dnsName)
    verifyTrue(((San)certSans[0]).val is Str)
    verifyEq(((San)certSans[0]).val, "san-test.fantom.org")
    verifyEq(((San)certSans[1]).type, SanType.dnsName)
    verifyTrue(((San)certSans[1]).val is Str)
    verifyEq(((San)certSans[1]).val, "www.san-test.fantom.org")
    verifyEq(((San)certSans[2]).type, SanType.ipAddr)
    verifyTrue(((San)certSans[2]).val is IpAddr)
    verifyEq(((San)certSans[2]).val, IpAddr("192.168.1.1"))
    verifyEq(((San)certSans[3]).type, SanType.ipAddr)
    verifyTrue(((San)certSans[3]).val is IpAddr)
    verifyEq(((San)certSans[3]).val, IpAddr("192.168.1.2"))
    verifyEq(((San)certSans[4]).type, SanType.rfc822Name)
    verifyTrue(((San)certSans[4]).val is Str)
    verifyEq(((San)certSans[4]).val, "user@fantom.org")
    verifyEq(((San)certSans[5]).type, SanType.uri)
    verifyTrue(((San)certSans[5]).val is Str)
    verifyEq(((San)certSans[5]).val, "https://fantom.org/doc")
    verifyEq(((San)certSans[6]).type, SanType.uri)
    verifyTrue(((San)certSans[6]).val is Str)
    verifyEq(((San)certSans[6]).val, "https://fantom.org")
    verifyEq(((San)certSans[7]).type, SanType.registeredId)
    verifyTrue(((San)certSans[7]).val is Str)
    verifyEq(((San)certSans[7]).val, "1.2.840.113549.1.9.1")
    verifyEq(((San)certSans[8]).type, SanType.registeredId)
    verifyTrue(((San)certSans[8]).val is Str)
    verifyEq(((San)certSans[8]).val, "1.2.840.113549.1.9.1")
    verifyEq(((San)certSans[9]).type, SanType.dirName)
    verifyTrue(((San)certSans[9]).val is Str)
    verifyEq(((San)certSans[9]).val, "C=US,CN=Test")

    csr2 := crypto.genCsr(pair, subjectDn)
    cert2 := crypto.certSigner(csr2)
              .notBefore(Date.today)
              .notAfter(Date.today + 90day)
              .subjectAltName("san-test.fantom.org")
              .subjectAltName(San.dnsName("www.san-test.fantom.org"))
              .subjectAltName(IpAddr("192.168.1.1"))
              .subjectAltName(San.ipAddr("192.168.1.2"))
              .subjectAltName(San.rfc822Name("user@fantom.org"))
              .subjectAltName(`https://fantom.org/doc`)
              .subjectAltName(San.uri("https://fantom.org"))
              .subjectAltName(Asn.oid("1.2.840.113549.1.9.1"))
              .subjectAltName(San.registeredId("1.2.840.113549.1.9.1"))
              .subjectAltName(San.dirName("C=US,CN=Test"))
              .sign

    certSans2 := cert2.subjectAltNames

    verifyEq(certSans2.size, 10)
    verifyEq(((San)certSans2[0]).type, SanType.dnsName)
    verifyTrue(((San)certSans2[0]).val is Str)
    verifyEq(((San)certSans2[0]).val, "san-test.fantom.org")
    verifyEq(((San)certSans2[1]).type, SanType.dnsName)
    verifyTrue(((San)certSans2[1]).val is Str)
    verifyEq(((San)certSans2[1]).val, "www.san-test.fantom.org")
    verifyEq(((San)certSans2[2]).type, SanType.ipAddr)
    verifyTrue(((San)certSans2[2]).val is IpAddr)
    verifyEq(((San)certSans2[2]).val, IpAddr("192.168.1.1"))
    verifyEq(((San)certSans2[3]).type, SanType.ipAddr)
    verifyTrue(((San)certSans2[3]).val is IpAddr)
    verifyEq(((San)certSans2[3]).val, IpAddr("192.168.1.2"))
    verifyEq(((San)certSans2[4]).type, SanType.rfc822Name)
    verifyTrue(((San)certSans2[4]).val is Str)
    verifyEq(((San)certSans2[4]).val, "user@fantom.org")
    verifyEq(((San)certSans2[5]).type, SanType.uri)
    verifyTrue(((San)certSans2[5]).val is Str)
    verifyEq(((San)certSans2[5]).val, "https://fantom.org/doc")
    verifyEq(((San)certSans2[6]).type, SanType.uri)
    verifyTrue(((San)certSans2[6]).val is Str)
    verifyEq(((San)certSans2[6]).val, "https://fantom.org")
    verifyEq(((San)certSans2[7]).type, SanType.registeredId)
    verifyTrue(((San)certSans2[7]).val is Str)
    verifyEq(((San)certSans2[7]).val, "1.2.840.113549.1.9.1")
    verifyEq(((San)certSans2[8]).type, SanType.registeredId)
    verifyTrue(((San)certSans2[8]).val is Str)
    verifyEq(((San)certSans2[8]).val, "1.2.840.113549.1.9.1")
    verifyEq(((San)certSans2[9]).type, SanType.dirName)
    verifyTrue(((San)certSans2[9]).val is Str)
    verifyEq(((San)certSans2[9]).val, "C=US,CN=Test")
  }

  Void testParsingOtherName()
  {
    openssl := Str<|-----BEGIN CERTIFICATE REQUEST-----
                    MIIDiTCCAnECAQAwZzELMAkGA1UEBhMCVVMxETAPBgNVBAgMCFZpcmdpbmlhMREw
                    DwYDVQQHDAhSaWNobW9uZDEPMA0GA1UECgwGRmFudG9tMQwwCgYDVQQLDANEZXYx
                    EzARBgNVBAMMCmZhbnRvbS5vcmcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
                    AoIBAQDZO/kv2qpVZQi4UMDz9yFd0Yg77d0gULxfJxhk8LDRqgi/NlkSZQ+VDgTP
                    h1AsxcqL1oLCv+FA45t06P5g712PrJaTQn5zlG9rjt0hCp21EN53O02dcJInFgKX
                    uF9zQVE4f6V82rY6bsPFLc3aVn5On7kuLUJVy2Y3MeQ/mxJfaInHuiOwhuAxJ8BK
                    7wKdz7I5sI21GIyfmOMJzhEEMe8OtAZjzX2v/QtxsUtTePmcKRQm823zOsCZv9b9
                    B0F1Q5Z124ASAxc6WpFMcWtrVg9qGsZVilEb3KsQdH++ZuZSVW+Uev4IQoElzt0Q
                    TvyKGVtl+jfq5xDyI09vRjQA6piHAgMBAAGggdwwgdkGCSqGSIb3DQEJDjGByzCB
                    yDCBxQYDVR0RBIG9MIG6ggpmYW50b20ub3Jngg53d3cuZmFudG9tLm9yZ4cEwKgB
                    AYEQYWRtaW5AZmFudG9tLm9yZ4YSaHR0cHM6Ly9mYW50b20ub3JniAUqAwQFBqRH
                    MEUxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKDAZGYW50b20xDjAMBgNVBAsMBVNhbGVz
                    MRUwEwYDVQQDDAxhbHQtZGlyLW5hbWWgIAYKKwYBBAGCNxQCA6ASDBB1c2VyQGV4
                    YW1wbGUuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQAogGlPvLZvEM67ksE+3b788QLi
                    paTgDbTP388UO/ciLfoijT9BEhqpYcAznVDtxLnK8B6GkJS/EAn3azOmxognYFxv
                    ZsHVdKyzwQ0x26RdvKdYj+wQMAph/vgRgBMLCEO1y+c0nlg+1Zq7BrpzjWP3+R1t
                    EZoQjmgU5Vvy9+edqRBia5W8dGPJc0iEKN8kntnUdxL9nDHydrUrGnOs2Bg8OR+T
                    PkhgcQCiSYTRLGQK5joijNGKIBAvmj9k7cLzxLWE2bdVBC6mQOp6tVVU9HL2tOrv
                    hX5p7NtMV7J0Aj02Rgoao+Ht8DPkbzttps8yJfq/Mh2nVQuFLz2+eKdCsgCM
                    -----END CERTIFICATE REQUEST-----|>

    decodedCsr := crypto.loadPem(openssl.in) as Csr
    verifyNotNull(decodedCsr)
    verifyEq(decodedCsr.subject, "C=US,ST=Virginia,L=Richmond,O=Fantom,OU=Dev,CN=fantom.org")

    parsed := parseOtherName((Buf)(decodedCsr.subjectAltNames[7].val))
    verifyEq(parsed, ["oid": "1.3.6.1.4.1.311.20.2.3", "value": "user@example.com"])
  }

//////////////////////////////////////////////////////////////////////////
// Example Parsing SanType.otherName (Won't work for all otherName values)
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse otherName from DER-encoded bytes
  ** AnotherName ::= SEQUENCE {
  **     type-id    OBJECT IDENTIFIER,
  **     value      [0] EXPLICIT ANY DEFINED BY type-id }
  **
  private Map parseOtherName(Buf buf)
  {
    // The [0] IMPLICIT tag replaces the SEQUENCE tag in ASN.1 encoding
    // Add the SEQUENCE tag (0x30) back before decoding

    seqBuf := Buf()
    seqBuf.write(0x30)      // SEQUENCE tag

    // Write length (handle both short and long form)
    len := buf.size
    if (len < 128)
    {
      seqBuf.write(len)
    }
    else
    {
      // Long form encoding
      numOctets := 0
      tempLen := len
      while (tempLen > 0) { numOctets++; tempLen = tempLen.shiftr(8) }
      seqBuf.write(0x80.or(numOctets))

      // Write length bytes in big-endian order
      for (i := numOctets - 1; i >= 0; i--)
      {
        seqBuf.write(len.shiftr(i * 8).and(0xff))
      }
    }

    // Ensure buf is at position 0 before writing
    buf.seek(0)
    seqBuf.writeBuf(buf)    // Content
    seqBuf.flip

    reader := BerReader(seqBuf.in)
    seq := reader.readObj as AsnSeq

    // OID + [0] EXPLICIT value (2 elements) - standard otherName
    if (seq.vals.size == 2)
    {
      // Standard format: OID + [0] EXPLICIT value
      oid := seq.vals[0] as AsnOid
      if (oid == null)
        throw Err("Expected OID as first element of otherName, got ${seq.vals[0].typeof}")

      contextTag := seq.vals[1]
      valueStr := extractOtherNameValue(contextTag)
      return ["oid": oid.oidStr, "value": valueStr]
    }
    return ["oid": "<unknown>", "value": "<unknown>"]
  }

  **
  ** Extract the actual value from the context-tagged wrapper
  **
  private Str extractOtherNameValue(AsnObj contextTag)
  {
    // The value is typically a string type (UTF8String, IA5String, etc.)
    // wrapped in the context tag [0]

    // If it's a sequence, we may need to unwrap further
    /*if (contextTag is AsnSeq)
    {
      seq := (AsnSeq)contextTag
      // Find the first non-OID element (the actual string value)
      for (i := 0; i < seq.vals.size; i++)
      {
        elem := seq.vals[i]
        // Skip OIDs, we want the string value
        if (elem is AsnOid) continue
        // Try to extract string from this element
        return extractStringValue(elem)
      }
      return ""
    }*/

    // If it's AsnBin (raw/unknown type), decode it
    if (contextTag is AsnBin)
    {
      bin := (AsnBin)contextTag
      contentBuf := bin.buf
      contentBuf.seek(0)

      // Parse as DER-encoded data
      if (contentBuf.size > 0)
      {
        innerReader := BerReader(contentBuf.in)
        innerObj := innerReader.readObj
        return extractStringValue(innerObj)
      }
      return ""
    }

    // Try to extract as string directly
    return extractStringValue(contextTag)
  }

  **
  ** Extract string value from various ASN.1 types
  **
  private Str extractStringValue(AsnObj obj)
  {
    val := obj.val

    // Handle direct string values
    if (val is Str) return ((Str)val).trim

    // Handle Buf - read as string
    if (val is Buf) return ((Buf)val).readAllStr.trim

    // Handle Unsafe wrapper (common in ASN.1)
    if (val.typeof.name == "Unsafe")
    {
      unsafe := (Unsafe)val
      innerVal := unsafe.val
      if (innerVal is Str) return ((Str)innerVal).trim
      if (innerVal is Buf) return ((Buf)innerVal).readAllStr.trim
    }

    // Fallback
    return val.toStr.trim
  }

}