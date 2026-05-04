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

    sans := ["example.com", "www.example.com", "api.example.com"]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, "O=Example Corp,CN=example.com")
    verifyNotNull(csr.opts)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
  }

  Void testCsrWithIpSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[IpAddr("192.168.1.100"), IpAddr("10.0.0.50")]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
  }

  Void testCsrWithUriSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[
      `https://api.example.com`,
      `https://api-v2.example.com`,
      `http://internal.example.com`
    ]

    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)
    verifyNotNull(csr.toStr)
    verifyTrue(csr.subjectAltNames.size == 3)
    verifyEq(((SubjectAltName)csr.subjectAltNames[0]).type, SubjectAltNameType.uniformResourceIdentifier)
    verifyEq(((SubjectAltName)csr.subjectAltNames[0]).value, `https://api.example.com`)
    verifyEq(((SubjectAltName)csr.subjectAltNames[1]).type, SubjectAltNameType.uniformResourceIdentifier)
    verifyEq(((SubjectAltName)csr.subjectAltNames[1]).value, `https://api-v2.example.com`)
    verifyEq(((SubjectAltName)csr.subjectAltNames[2]).type, SubjectAltNameType.uniformResourceIdentifier)
    verifyEq(((SubjectAltName)csr.subjectAltNames[2]).value, `http://internal.example.com`)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
  }

  Void testCsrWithRFC822San()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[["value": "user@fantom.org", "type": SubjectAltNameType.rfc822Name]]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    decodedSans := decodedCsr.subjectAltNames
    verifyEq(decodedSans.size, 1)
    verifyEq(((SubjectAltName)decodedSans[0]).type, SubjectAltNameType.rfc822Name)
    verifyEq(((SubjectAltName)decodedSans[0]).value, "user@fantom.org")
  }

  Void testCsrWithRegisteredIdSan()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := Obj[["value": Asn.oid("1.2.3.4.5.6"), "type": SubjectAltNameType.registeredID]]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    verify(pem.contains("-----BEGIN CERTIFICATE REQUEST-----"))

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    decodedSans := decodedCsr.subjectAltNames
    verifyEq(decodedSans.size, 1)
    verifyEq(((SubjectAltName)decodedSans[0]).type, SubjectAltNameType.registeredID)
    verifyEq(((SubjectAltName)decodedSans[0]).value, Asn.oid("1.2.3.4.5.6"))
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

    verifyEq(csr.subject, subjectDn)

    pem := csr.toStr
    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)
    verifyEq(decodedCsr.subject, "CN=Fantom")
    Obj[] values := decodedCsr.subjectAltNames.mapNotNull |san| { san.value }
    verifyEq(values, sans)
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

    Obj[] values := sans.mapNotNull |san| { san.value }
    verifyEq(values, Obj["fantom.org", "www.fantom.org", IpAddr("192.168.1.1")])
  }

  Void testCsrSanToSignedCert()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=Fantom"

    sans := ["san-test.fantom.org",
             "www.san-test.fantom.org",
             IpAddr("192.168.1.1"),
             ["value": "user@fantom.org", "type": SubjectAltNameType.rfc822Name],
             `https://fantom.org/doc`]
    csr := crypto.genCsr(pair, subjectDn, ["subjectAltNames": sans])

    cert := crypto.certSigner(csr)
              .notBefore(Date.today)
              .notAfter(Date.today + 90day)
              .sign

    verifyNotNull(cert)
    verifyEq(cert.subject, "CN=Fantom")
    certSans := cert.subjectAltNames
    verifyEq(certSans.size, 5)
    verifyEq(((SubjectAltName)certSans[0]).type, SubjectAltNameType.dNSName)
    verifyTrue(((SubjectAltName)certSans[0]).value is Str)
    verifyEq(((SubjectAltName)certSans[0]).value, "san-test.fantom.org")
    verifyEq(((SubjectAltName)certSans[1]).type, SubjectAltNameType.dNSName)
    verifyTrue(((SubjectAltName)certSans[1]).value is Str)
    verifyEq(((SubjectAltName)certSans[1]).value, "www.san-test.fantom.org")
    verifyEq(((SubjectAltName)certSans[2]).type, SubjectAltNameType.iPAddress)
    verifyTrue(((SubjectAltName)certSans[2]).value is IpAddr)
    verifyEq(((SubjectAltName)certSans[2]).value, IpAddr("192.168.1.1"))
    verifyEq(((SubjectAltName)certSans[3]).type, SubjectAltNameType.rfc822Name)
    verifyTrue(((SubjectAltName)certSans[3]).value is Str)
    verifyEq(((SubjectAltName)certSans[3]).value, "user@fantom.org")
    verifyEq(((SubjectAltName)certSans[4]).type, SubjectAltNameType.uniformResourceIdentifier)
    verifyTrue(((SubjectAltName)certSans[4]).value is Uri)
    verifyEq(((SubjectAltName)certSans[4]).value, `https://fantom.org/doc`)
  }

}