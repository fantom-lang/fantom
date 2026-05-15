//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2026 Ross Schwalm   Creation
//

**
** Test cases for X.509 Certificate functionality
**
class CertTest : CryptoTest
{
  Void testSelfSigned()
  {
    keys   := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=test,OU=engineering,O=Example Corp,C=US"
    csr    := crypto.genCsr(keys, subjectDn)
    cert   := crypto.certSigner(csr)
                .notBefore(Date.today)
                .notAfter(Date.today + 90day)
                .basicConstraints
                .sign

    //Cert subject DN components normalized to the standard X.500 order
    verifyEq(cert.subject, "C=US,O=Example Corp,OU=engineering,CN=test")
    verifyEq(cert.pub.toStr, keys.pub.toStr)
  }

  Void testSelfSignedWithSan()
  {
    keys   := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=test,OU=engineering,O=Example Corp,C=US"
    csr    := crypto.genCsr(keys, subjectDn)
    cert   := crypto.certSigner(csr)
                .notBefore(Date.today)
                .notAfter(Date.today + 90day)
                .subjectAltName(San.dnsName("www.fantom.org"))
                .subjectAltName(San.uri("https://fantom.org/download"))
                .subjectAltName(San.rfc822Name("test@fantom.org"))
                .subjectAltName(San.ipAddr("192.168.1.1"))
                .subjectAltName(San.registeredId("1.2.3.4.5.6"))
                .subjectAltName(San.dirName("C=US,O=Fantom,CN=dev"))
                .basicConstraints
                .sign

    //Cert subject DN components normalized to the standard X.500 order
    verifyEq(cert.subject, "C=US,O=Example Corp,OU=engineering,CN=test")
    verifyEq(cert.pub.toStr, keys.pub.toStr)
    verifyEq(cert->notBefore, Date.today)
    verifyEq(cert->notAfter, Date.today + 90day)
    verifyTrue(cert.isSelfSigned)
    verifyFalse(cert.isCA)

    sans := cert.subjectAltNames
    verifyEq(sans.size, 6)

    Str[] values := sans.mapNotNull |san->Str| { san.toStr }
    verifyEq(values, Str["DNS:www.fantom.org",
                         "URI:https://fantom.org/download",
                         "email:test@fantom.org",
                         "IP:192.168.1.1",
                         "registeredId:1.2.3.4.5.6",
                         "dirName:C=US,O=Fantom,CN=dev"])

  }

  Void testOpensslCA()
  {
    openssl := Str<|-----BEGIN CERTIFICATE-----
                    MIIFuTCCA6GgAwIBAgIUVma2KdnO8YP5xxC5tayV61n9fbUwDQYJKoZIhvcNAQEL
                    BQAwZDELMAkGA1UEBhMCVVMxETAPBgNVBAgMCFZpcmdpbmlhMREwDwYDVQQHDAhS
                    aWNobW9uZDEPMA0GA1UECgwGRmFudG9tMQwwCgYDVQQLDANEZXYxEDAOBgNVBAMM
                    B1Rlc3QgQ0EwHhcNMjYwNDI5MDM0NDU5WhcNMzYwNDI2MDM0NDU5WjBkMQswCQYD
                    VQQGEwJVUzERMA8GA1UECAwIVmlyZ2luaWExETAPBgNVBAcMCFJpY2htb25kMQ8w
                    DQYDVQQKDAZGYW50b20xDDAKBgNVBAsMA0RldjEQMA4GA1UEAwwHVGVzdCBDQTCC
                    AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANsoSCu3WfqtqiAReYv5zS07
                    FTTCFyitSOSV0clEMOhJ6Wc6IH3aedpB8dk3VrODGq8d3A8xvVPibadiAAN+BNut
                    /nVd6n0+9LYiLXqExPvQV4UWCMYj9ZTXbwOFCo076Ctt4zNnLo2BXjxt3wrkhMAW
                    I8Dbs3wdywj3K9J5ex7vXZUxxnmU2UNwpPOVCTdA54WDXjqnagOgf704EyvDcgmI
                    YaVxGn/+qCnn6EYL49V02nwc+pkYiGXr1ySaSU4Dp8RoEGw6mmHrEsujkJsloynC
                    t9Onvl62B4NyorhrHD1ZGFAtlo6CErtbdhxWbquEzX7tx6t9iy9PX3kY5Kqzj5bd
                    MxBB0FTCkAPMw/zkN4Bm3tIThylbWxy7ywz7ACrkJa+RRosdFHg361Z4CeMf2stB
                    d16td2ttljBbULlx7stP1zAvrsNtAFNHQbmkAKVuOT06NbG/Ow63XRTv/zzMtrwk
                    M3BX4412dYofw2n50rYZ3fEG36tdEpytMQnM6r1y0++yWzPTSJRH3FqRMOh8aOzP
                    C7xAEpObhlByUCdeGhsukzCHF9SigYpBZk2iEWzizZBXq2D26dvPy5ox9zLfm4rA
                    SKrjuRCYa3Vckg3heBzMP2ZAtCIWxMgHukKL/G6d6sm0YIg/yTE7GgGwYuucNUeI
                    6I9ij/vuK1uvd+NVqYHTAgMBAAGjYzBhMB0GA1UdDgQWBBSiQZptayrGrKc5imtd
                    f0L4AGzAATAfBgNVHSMEGDAWgBSiQZptayrGrKc5imtdf0L4AGzAATAPBgNVHRMB
                    Af8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQsFAAOCAgEALEHt
                    H6au7BpAoHl8pTtM6iVjCW2pVNZZ9GMTeqpbtk/gkPkS1VN9IwRtT2lk8jqi0+w2
                    Yvyn4GxTAguQ+z7kovI+qkxzsfs8ZDbzA2JX3qbKTFdptals/X8GWOa2QRSKDucD
                    dnecGufxT3fSdV8ggii/4aoQSzMIsOzugTomVw5A/BEml30prBDFygTwBrPFggjM
                    Xz7VPtasYLCA6gd5PukgjzUKX2O2daQ71joz+QqbL12mOfSLOdVRfY9//07Qp86y
                    YgxzkfauqK+/hQFeGreo4mKvXjuxk4B+duLsZqcPWurZJqZeXXyrw3QYv8Vx4gJk
                    kJApWMePsPSC+tsOjPY4KbfXzSIhXVffOC2w9oDwdtQqJ+pBiY5izlG8Nshsy9wp
                    vj7vnI5pIyvm/r9QxT4krpprHenxuwoiu6gTKxAUR/d1F5lI70dnRfnIPCn3Mm2S
                    P+pFm0AwWU0ugQKe6igNVe5e8bN5hJ+nzqAMTUvuYGLf+MFPzs3Ye4GaHRr+Whzm
                    mmzDyhMRg2GW8LjuyEPFvhgb+VdEVKjVXWjqSE8oBcc68Jlo/zAK6ihKu6qPDX33
                    cT2Lw580PnczSkDYCuhW5FoHOEDynq54/p/4Uw9ZuPnUdNgY7PxfFJyXpiRb/qES
                    x3P1zSVC6moc1z2MQ7rJ13Mjb60XtDnm1pccWEU=
                    -----END CERTIFICATE-----|>

    decodedCert := crypto.loadPem(openssl.in) as Cert
    verifyNotNull(decodedCert)
    verifyTrue(decodedCert.isSelfSigned)
    verifyTrue(decodedCert.isCA)
    verifyEq(decodedCert.subject, "C=US,ST=Virginia,L=Richmond,O=Fantom,OU=Dev,CN=Test CA")
    verifyEq(decodedCert.issuer, "C=US,ST=Virginia,L=Richmond,O=Fantom,OU=Dev,CN=Test CA")
  }

  Void testCertRoundTrip()
  {
    keys   := crypto.genKeyPair("RSA", 2048)
    subjectDn := "CN=test,OU=engineering,O=Example Corp,C=US"
    csr    := crypto.genCsr(keys, subjectDn, ["subjectAltNames": ["fantom.org", "www.fantom.org"]])
    cert   := crypto.certSigner(csr)
                .notBefore(Date.today)
                .notAfter(Date.today + 90day)
                .subjectAltName(`https://fantom.org/doc`)
                .subjectAltName(San.rfc822Name("test@fantom.org"))
                .basicConstraints
                .sign

    pem := cert.toStr
    decodedCert := crypto.loadPem(pem.in) as Cert
    verifyNotNull(decodedCert)

    //Cert subject DN components normalized to the standard X.500 order
    verifyEq(decodedCert.subject, "C=US,O=Example Corp,OU=engineering,CN=test")
    verifyEq(decodedCert.pub.toStr, keys.pub.toStr)
    verifyEq(decodedCert->notBefore, Date.today)
    verifyEq(decodedCert->notAfter, Date.today + 90day)
    verifyTrue(decodedCert.isSelfSigned)
    verifyFalse(decodedCert.isCA)

    sans := decodedCert.subjectAltNames
    verifyEq(sans.size, 4)

    Str[] values := sans.mapNotNull |san->Str| { san.toStr }
    verifyEq(values, Str["DNS:fantom.org",
                         "DNS:www.fantom.org",
                         "URI:https://fantom.org/doc",
                         "email:test@fantom.org"])
  }

  Void testOpensslCert()
  {
    openssl := Str<|-----BEGIN CERTIFICATE-----
                    MIIERzCCAy+gAwIBAgIUBTfsUVyALGR75QYjsDdGljs70IAwDQYJKoZIhvcNAQEL
                    BQAwZzELMAkGA1UEBhMCVVMxETAPBgNVBAgMCFZpcmdpbmlhMREwDwYDVQQHDAhS
                    aWNobW9uZDEPMA0GA1UECgwGRmFudG9tMQwwCgYDVQQLDANEZXYxEzARBgNVBAMM
                    CmZhbnRvbS5vcmcwHhcNMjYwNDI4MjExNDA3WhcNMjcwNDI4MjExNDA3WjBnMQsw
                    CQYDVQQGEwJVUzERMA8GA1UECAwIVmlyZ2luaWExETAPBgNVBAcMCFJpY2htb25k
                    MQ8wDQYDVQQKDAZGYW50b20xDDAKBgNVBAsMA0RldjETMBEGA1UEAwwKZmFudG9t
                    Lm9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKSTT58CquioZfXB
                    s1Wvhcseivdvo0DP/KchqtBNQMGrljco7qdwDU2FXQzM+H6idj5qPH97nd11j2J+
                    2QVPR/VDGxUZyvCyv4UM1Lp79YBO9s4STWUk/KlhBiQxN01vfTE4JXQl3vyNneF9
                    2YsKEWY1QA01VOJKapKlptGFDTuSyh5ZWeMBzGQh8bZleK3dSL287S8BT6g4nbdv
                    8BiPSoA+mZdGi7Z1RQUGuUwCja/TZschV3qT1Cwxj6Rk9FwwtYDpu9h4h6lm6482
                    n4BsHAWOTDVhPB3KM+TNVZN50AoIopCxjFtGGi8MXhyj09T+R2QSsUp68dlUs3YV
                    NcDVESMCAwEAAaOB6jCB5zCBxQYDVR0RBIG9MIG6ggpmYW50b20ub3Jngg53d3cu
                    ZmFudG9tLm9yZ4cEwKgBAYEQYWRtaW5AZmFudG9tLm9yZ4YSaHR0cHM6Ly9mYW50
                    b20ub3JniAUqAwQFBqRHMEUxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKDAZGYW50b20x
                    DjAMBgNVBAsMBVNhbGVzMRUwEwYDVQQDDAxhbHQtZGlyLW5hbWWgIAYKKwYBBAGC
                    NxQCA6ASDBB1c2VyQGV4YW1wbGUuY29tMB0GA1UdDgQWBBRgGJuunoaOX+l2Mub1
                    F16ucZ3SojANBgkqhkiG9w0BAQsFAAOCAQEAcqTgYGfzeHkrHxk87wDHiWHInmQs
                    23IJiqQany88AI/USY2D9p6F66VhncdKVCFIwlga4z6kfbkhNMdIK+MEZo8FZT3a
                    iD5mN6oOb2ITGRh/UXVSanGirlQA6c4xegu12Xm+B5qbAvM1Updm5fFTG/Q1KZmv
                    Wpqpnf/XtCIPZC/16+UmL+Te8WUr/aEV4zpNycgr446ujUn3pWr40ErQ6QBPS5RM
                    wbA3ePaUP3CVXqh3IaBeQ9UAqMKbvCkulYTStVjNTIu2llyAHrYuNKYAgTR3JtP0
                    p0+zauSmwyW9s1MMpWmmcqHjJWbsiimkIbq+fH1HUIH9MYtui8wMNufE1Q==
                    -----END CERTIFICATE-----|>

    decodedCert := crypto.loadPem(openssl.in) as Cert
    verifyNotNull(decodedCert)
    verifyTrue(decodedCert.isSelfSigned)
    verifyFalse(decodedCert.isCA)
    verifyEq(decodedCert.subject, "C=US,ST=Virginia,L=Richmond,O=Fantom,OU=Dev,CN=fantom.org")
    verifyEq(decodedCert->notBefore, Date("2026-04-28"))
    verifyEq(decodedCert->notAfter, Date("2027-04-28"))

    sans := decodedCert.subjectAltNames
    verifyEq(sans.size, 8)

    Str[] values := sans.mapNotNull |san->Str| { san.toStr }
    verifyEq(values, Str["DNS:fantom.org",
                         "DNS:www.fantom.org",
                         "IP:192.168.1.1",
                         "email:admin@fantom.org",
                         "URI:https://fantom.org",
                         "registeredId:1.2.3.4.5.6",
                         "dirName:C=US,O=Fantom,OU=Sales,CN=alt-dir-name",
                         "otherName:<bytes>"])
  }

}