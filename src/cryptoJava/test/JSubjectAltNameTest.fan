//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2026  Ross Schwalm  Creation
//

using asn1
using inet
using crypto

**
** JSubjectAltNameTest - Tests for RFC 5280 GeneralName types
**
class JSubjectAltNameTest : CryptoTest
{

  Void testRfc822NameEncoding()
  {
    san := JSubjectAltName.fromValue("user@fantom.org", SubjectAltNameType.rfc822Name)

    verifyEq(san.tagId, 1)
    verifyEq(san.type, SubjectAltNameType.rfc822Name)
    verifyEq(san.value, "user@fantom.org")
    verifyEq(san.toStr, "email:user@fantom.org")

    asn := san.asn
    verify(asn.tags.first.cls.isContext)
    verifyEq(asn.tags.first.id, 1)
  }

  Void testRfc822NameDecoding()
  {
    san := JSubjectAltName.fromTag(1, "user@fantom.org")

    verifyEq(san.tagId, 1)
    verifyEq(san.type, SubjectAltNameType.rfc822Name)
    verifyEq(san.value, "user@fantom.org")
  }

  Void testRfc822NameVariations()
  {
    emails := [
      "simple@fantom.org",
      "user.name@fantom.org",
      "user+tag@fantom.org",
      "user_123@test-domain.fantom.org"
    ]

    emails.each |email|
    {
      san := JSubjectAltName.fromValue(email, SubjectAltNameType.rfc822Name)
      verifyEq(san.value, email)
      verifyEq(san.type, SubjectAltNameType.rfc822Name)
    }
  }

  Void testRegisteredIdWithOid()
  {
    oid := Asn.oid("1.2.840.113549.1.9.1") // emailAddress OID
    san := JSubjectAltName.fromValue(oid, SubjectAltNameType.registeredID)

    verifyEq(san.tagId, 8)
    verifyEq(san.type, SubjectAltNameType.registeredID)
    verify(san.value is AsnOid)
    verifyEq(((AsnOid)san.value).oidStr, "1.2.840.113549.1.9.1")

    asn := san.asn
    verify(asn.tags.first.cls.isContext)
    verifyEq(asn.tags.first.id, 8)
  }

  Void testRegisteredIdWithString()
  {
    san := JSubjectAltName.fromValue(Asn.oid("2.5.4.3"), SubjectAltNameType.registeredID)

    verifyEq(san.tagId, 8)
    verifyEq(san.type, SubjectAltNameType.registeredID)
    verify(san.value is AsnOid)
    verifyEq(((AsnOid)san.value).oidStr, "2.5.4.3")
  }

  Void testRegisteredIdDecoding()
  {
    oid := Asn.oid("1.3.6.1.4.1.311.20.2.3") // Microsoft UPN OID
    san := JSubjectAltName.fromTag(8, oid)

    verifyEq(san.tagId, 8)
    verifyEq(san.type, SubjectAltNameType.registeredID)
    verify(san.value is AsnOid)
    verifyEq(((AsnOid)san.value).oidStr, "1.3.6.1.4.1.311.20.2.3")
  }

  Void testRegisteredIdVariousOids()
  {
    oids := [
      "1.2.3.4.5",                      // Simple OID
      "1.2.840.113549.1.9.1",           // emailAddress
      "2.5.4.3",                        // commonName
      "1.3.6.1.4.1.311.20.2.3"          // Microsoft UPN
    ]

    oids.each |oidStr|
    {
      oid := Asn.oid(oidStr)
      san := JSubjectAltName.fromValue(oid, SubjectAltNameType.registeredID)
      verifyEq(((AsnOid)san.value).oidStr, oidStr)
      verifyEq(san.type, SubjectAltNameType.registeredID)
    }
  }

  Void testDnsName()
  {
    san := JSubjectAltName.fromValue("example.com", SubjectAltNameType.dNSName)

    verifyEq(san.tagId, 2)
    verifyEq(san.type, SubjectAltNameType.dNSName)
    verifyEq(san.value, "example.com")
    verifyEq(san.toStr, "DNS:example.com")
  }

  Void testUri()
  {
    uri := `https://fantom.org/doc`
    san := JSubjectAltName.fromValue(uri, SubjectAltNameType.uniformResourceIdentifier)

    verifyEq(san.tagId, 6)
    verifyEq(san.type, SubjectAltNameType.uniformResourceIdentifier)
    verifyEq(san.value, uri)
    verify(san.value is Uri)
  }

  Void testIpAddress()
  {
    ip := IpAddr("192.168.1.1")
    san := JSubjectAltName.fromValue(ip, SubjectAltNameType.iPAddress)

    verifyEq(san.tagId, 7)
    verifyEq(san.type, SubjectAltNameType.iPAddress)
    verifyEq(san.value, ip)
    verify(san.value is IpAddr)
  }

  Void testTypeAutoDetection()
  {
    // String defaults to dNSName
    san1 := JSubjectAltName.fromValue("fantom.org", null)
    verifyEq(san1.type, SubjectAltNameType.dNSName)

    // Uri gets uniformResourceIdentifier
    san2 := JSubjectAltName.fromValue(`https://fantom.org`, null)
    verifyEq(san2.type, SubjectAltNameType.uniformResourceIdentifier)

    // IpAddr gets iPAddress
    san3 := JSubjectAltName.fromValue(IpAddr("10.0.0.1"), null)
    verifyEq(san3.type, SubjectAltNameType.iPAddress)

    // AsnOid gets registeredID
    san4 := JSubjectAltName.fromValue(Asn.oid("1.2.3"), null)
    verifyEq(san4.type, SubjectAltNameType.registeredID)
  }

//////////////////////////////////////////////////////////////////////////
// Error Cases
//////////////////////////////////////////////////////////////////////////

  Void testUnsupportedTypes()
  {
    // Test that unimplemented types are gracefully handled during decoding
    // but throw UnsupportedErr when trying to encode

    san3 := JSubjectAltName.fromTag(3, "test")
    verifyEq(san3.type, SubjectAltNameType.x400Address)
    verifyEq(san3.value, "test")
    verifyErr(UnsupportedErr#) { san3.asn }

    san5 := JSubjectAltName.fromTag(5, "test")
    verifyEq(san5.type, SubjectAltNameType.ediPartyName)
    verifyEq(san5.value, "test")
    verifyErr(UnsupportedErr#) { san5.asn }
  }

  Void testOtherNameErrors()
  {
    // Since encoding is not supported, all attempts throw UnsupportedErr
    verifyErr(UnsupportedErr#) {
      map := ["oid": "1.2.3"]  // Missing "value"
      san := JSubjectAltName.fromValue(map, SubjectAltNameType.otherName)
      san.asn
    }

    verifyErr(UnsupportedErr#) {
      map := ["value": "test"]  // Missing "oid"
      san := JSubjectAltName.fromValue(map, SubjectAltNameType.otherName)
      san.asn
    }
  }

//////////////////////////////////////////////////////////////////////////
// Round-Trip Tests
//////////////////////////////////////////////////////////////////////////

  Void testRfc822RoundTrip()
  {
    original := "test@fantom.org"
    san1 := JSubjectAltName.fromValue(original, SubjectAltNameType.rfc822Name)

    asn := san1.asn
    decoded := asn.str

    san2 := JSubjectAltName.fromTag(1, decoded)
    verifyEq(san2.value, original)
  }

  Void testRegisteredIdRoundTrip()
  {
    oidStr := "1.2.840.10045.4.3.2" // ecdsa-with-SHA256
    oid := Asn.oid(oidStr)
    san1 := JSubjectAltName.fromValue(oid, SubjectAltNameType.registeredID)

    asn := san1.asn
    verify(asn.tags.first.cls.isContext)
    verifyEq(asn.tags.first.id, 8)

    decodedOid := asn.oid
    san2 := JSubjectAltName.fromTag(8, decodedOid)

    verifyEq(((AsnOid)san2.value).oidStr, oidStr)
  }

//////////////////////////////////////////////////////////////////////////
// Integration Tests
//////////////////////////////////////////////////////////////////////////

  Void testMixedSanList()
  {
    sans := [
      JSubjectAltName.fromValue("www.fantom.org", SubjectAltNameType.dNSName),
      JSubjectAltName.fromValue("user@fantom.org", SubjectAltNameType.rfc822Name),
      JSubjectAltName.fromValue(`https://fantom.org`, SubjectAltNameType.uniformResourceIdentifier),
      JSubjectAltName.fromValue(IpAddr("192.168.1.1"), SubjectAltNameType.iPAddress),
      JSubjectAltName.fromValue(Asn.oid("1.2.3.4"), SubjectAltNameType.registeredID),
      JSubjectAltName.fromValue("www.fantom.org", SubjectAltNameType.dNSName),
      JSubjectAltName.fromValue("user@fantom.org", SubjectAltNameType.rfc822Name),
      JSubjectAltName.fromValue(["oid": "1.2.3.4", "value": "custom"], SubjectAltNameType.otherName),
      JSubjectAltName.fromValue("CN=User,O=Fantom,C=US", SubjectAltNameType.directoryName),
      JSubjectAltName.fromValue(Asn.oid("2.5.4.3"), SubjectAltNameType.registeredID)
    ]

    verifyEq(sans.size, 10)
    verifyEq(sans[0].type, SubjectAltNameType.dNSName)
    verifyEq(sans[1].type, SubjectAltNameType.rfc822Name)
    verifyEq(sans[2].type, SubjectAltNameType.uniformResourceIdentifier)
    verifyEq(sans[3].type, SubjectAltNameType.iPAddress)
    verifyEq(sans[4].type, SubjectAltNameType.registeredID)
    verifyEq(sans[5].type, SubjectAltNameType.dNSName)
    verifyEq(sans[6].type, SubjectAltNameType.rfc822Name)
    verifyEq(sans[7].type, SubjectAltNameType.otherName)
    verifyEq(sans[8].type, SubjectAltNameType.directoryName)
    verifyEq(sans[9].type, SubjectAltNameType.registeredID)
  }

  Void testOtherNameBasic()
  {
    map := ["oid": "1.2.3.4.5", "value": "test value"]
    san := JSubjectAltName.fromValue(map, SubjectAltNameType.otherName)

    verifyEq(san.type, SubjectAltNameType.otherName)
    verifyEq(san.tagId, 0)

    val := san.value
    verify(val is Map)
    verifyEq(((Map)val)["oid"], "1.2.3.4.5")
    verifyEq(((Map)val)["value"], "test value")
  }

  Void testOtherNameWithOidObj()
  {
    map := ["oid": Asn.oid("1.2.840.113549.1.9.1"), "value": "user@fantom.org"]
    san := JSubjectAltName.fromValue(map, SubjectAltNameType.otherName)

    verifyErr(UnsupportedErr#) {
      asn := san.asn
    }
  }

  Void testDirectoryNameBasic()
  {
    dn := "CN=Test User,OU=Dev,O=Fantom,C=US"
    san := JSubjectAltName.fromValue(dn, SubjectAltNameType.directoryName)

    verifyEq(san.type, SubjectAltNameType.directoryName)
    verifyEq(san.tagId, 4)

    verifyEq(san.value, dn)
  }

  Void testDirectoryNameEncoding()
  {
    dn := "CN=User,O=Fantom,C=US"
    san := JSubjectAltName.fromValue(dn, SubjectAltNameType.directoryName)

    // Encoding not yet supported
    verifyErr(UnsupportedErr#) {
      asn := san.asn
    }
  }

  Void testDirectoryNameRoundTrip()
  {
    dn := "CN=John Doe,OU=Engineering,O=Fantom,C=GB"
    san := JSubjectAltName.fromValue(dn, SubjectAltNameType.directoryName)

    verifyEq(san.value, dn)
    verifyEq(san.type, SubjectAltNameType.directoryName)
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

    verify(decodedCsr.subjectAltNames.size >= 7)

    sanStrs := decodedCsr.subjectAltNames.map |san| { san.toStr }
    verify(sanStrs.any |s| { ((Str)s).startsWith("DNS:fantom.org") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("DNS:www.fantom.org") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("IP Address:192.168.1.1") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("email:admin@fantom.org") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("URI:https://fantom.org") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("Registered ID:") && ((Str)s).contains("1.2.3.4.5.6") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("DirName:") && ((Str)s).contains("C=US") })
    verify(sanStrs.any |s| { ((Str)s).startsWith("othername:") && ((Str)s).contains("oid=") })
  }
}
