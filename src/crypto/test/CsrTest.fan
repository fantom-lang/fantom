//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2026 Ross Schwalm   Creation
//

**
** Test cases for Certificate Signing Request (CSR) functionality
** based on RFC 5967 - The application/pkcs10 Media Type
**
class CsrTest : CryptoTest
{

//////////////////////////////////////////////////////////////////////////
// Basic CSR Generation
//////////////////////////////////////////////////////////////////////////

  Void testBasicCsrGeneration()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "cn=test"
    csr := crypto.genCsr(pair, subjectDn)

    verifyEq(csr.subject, "CN=test")
    verifyEq(csr.pub.algorithm, "RSA")
    verifyNotNull(csr.opts)
  }

  Void testCsrWithComplexSubjectDn()
  {
    // Test with a more complex X.500 distinguished name (RFC 4514)
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "cn=Test,ou=Engineering,o=Example Corp,st=Virginia,c=US"
    csr := crypto.genCsr(pair, subjectDn)

    verifyEq(csr.subject, "C=US,ST=Virginia,O=Example Corp,OU=Engineering,CN=Test")
    verifyEq(csr.pub, pair.pub)
  }

  Void testOpensslCsr()
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

    sans := decodedCsr.subjectAltNames
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

//////////////////////////////////////////////////////////////////////////
// Algorithm Tests
//////////////////////////////////////////////////////////////////////////

  Void testCsrWithDifferentAlgorithms()
  {
    pair := crypto.genKeyPair("RSA", 2048)

    // Test with SHA-256 (default for many implementations)
    csr1 := crypto.genCsr(pair, "cn=test", ["algorithm": "sha256WithRSAEncryption"])
    verifyEq(csr1.opts["algorithm"], "sha256WithRSAEncryption")

    // Test with SHA-512
    csr2 := crypto.genCsr(pair, "cn=test", ["algorithm": "sha512WithRSAEncryption"])
    verifyEq(csr2.opts["algorithm"], "sha512WithRSAEncryption")
  }

//////////////////////////////////////////////////////////////////////////
// RFC 5967 Compliance Tests
//////////////////////////////////////////////////////////////////////////

  Void testRfc5967()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "cn=test,ou=example.org,o=Example Inc,c=US"
    csr := crypto.genCsr(pair, subjectDn)

    pem := csr.toStr

    // Verify PEM format (RFC 5967 Section 2.1)
    verify(pem.contains("-----BEGIN"))
    verify(pem.contains("-----END"))
    verify(pem.contains("CERTIFICATE REQUEST") || pem.contains("NEW CERTIFICATE REQUEST"))
  }

  Void testCsrRoundTrip()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    subjectDn := "cn=roundtrip-test,ou=testing,o=Example"
    originalCsr := crypto.genCsr(pair, subjectDn)

    pem := originalCsr.toStr

    decodedCsr := crypto.loadPem(pem.in) as Csr
    verifyNotNull(decodedCsr)

    verifyEq(decodedCsr.subject, "O=Example,OU=testing,CN=roundtrip-test")
    verifyEq(decodedCsr.pub.algorithm, originalCsr.pub.algorithm)
    verifyEq(decodedCsr.pub.encoded.toStr, originalCsr.pub.encoded.toStr)
  }

  Void testCsrWithDifferentKeySizes()
  {
    pair2048 := crypto.genKeyPair("RSA", 2048)
    csr2048 := crypto.genCsr(pair2048, "cn=test-2048")
    verify(csr2048.pub.encoded.size > 0)

    pair4096 := crypto.genKeyPair("RSA", 4096)
    csr4096 := crypto.genCsr(pair4096, "cn=test-4096")
    verify(csr4096.pub.encoded.size > csr2048.pub.encoded.size)
  }

  Void testCsrPublicKey()
  {
    pair := crypto.genKeyPair("RSA", 2048)
    csr := crypto.genCsr(pair, "cn=pubkey-test")

    verifyEq(csr.pub.algorithm, pair.pub.algorithm)
    verifyEq(csr.pub.format, pair.pub.format)
    verifyEq(csr.pub.encoded.toStr, pair.pub.encoded.toStr)
  }

}
