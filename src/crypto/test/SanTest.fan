//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2026  Ross Schwalm  Creation
//

**
** SanTest - Tests for RFC 5280 GeneralName types
**
class SanTest : CryptoTest
{

  Void testEmail()
  {
    san := San.rfc822Name("user@fantom.org")

    verifyEq(((SanType)san.type).tagId, 1)
    verifyEq(san.type, SanType.rfc822Name)
    verifyEq(san.val, "user@fantom.org")
    verifyEq(san.toStr, "email:user@fantom.org")
  }

  Void testDns()
  {
    san := San.dnsName("example.com")

    verifyEq(((SanType)san.type).tagId, 2)
    verifyEq(san.type, SanType.dnsName)
    verifyEq(san.val, "example.com")
    verifyEq(san.toStr, "DNS:example.com")
  }

  Void testUri()
  {
    //Uri
    uri := `https://fantom.org/doc`
    san := San.uri(uri)

    verifyEq(((SanType)san.type).tagId, 6)
    verifyEq(san.type, SanType.uri)
    verify(san.val is Str)
    verifyEq(san.val, "https://fantom.org/doc")
    verifyEq(san.toStr, "URI:https://fantom.org/doc")

    san2 := San.uri(`https://fantom.org`)
    verifyEq(san2.val, "https://fantom.org/")

    //Str
    san3 := San.uri("https://fantom.org")
    verifyEq(san3.val, "https://fantom.org")
  }

  Void testIpAddr()
  {
    //Str
    san := San.ipAddr("192.168.1.1")

    verifyEq(((SanType)san.type).tagId, 7)
    verifyEq(san.type, SanType.ipAddr)
    verifyEq(san.val, Type.find("inet::IpAddr").make(["192.168.1.1"]))
    verify(Type.find("inet::IpAddr").fits(san.val.typeof))
    verifyEq(san.toStr, "IP:192.168.1.1")

    //IpAddr
    san2 := San.ipAddr(Type.find("inet::IpAddr").make(["192.168.1.2"]))

    verify(Type.find("inet::IpAddr").fits(san2.val.typeof))
    verifyEq(san2.toStr, "IP:192.168.1.2")
  }

  Void testRegisteredId()
  {
    //AsnOid
    oid := Type.find("asn1::Asn").method("oid").call("1.2.840.113549.1.9.1") //emailAddress OID
    san := San.registeredId(oid)

    verifyEq(((SanType)san.type).tagId, 8)
    verifyEq(san.type, SanType.registeredId)
    verify(san.val is Str)
    verifyEq(san.val, "1.2.840.113549.1.9.1")
    verifyEq(san.toStr, "registeredId:1.2.840.113549.1.9.1")

    //Str
    san2 := San.registeredId("1.2.840.113549.1.9.1")

    verifyEq(((SanType)san.type).tagId, 8)
    verifyEq(san.type, SanType.registeredId)
    verify(san.val is Str)
    verifyEq(san.val, "1.2.840.113549.1.9.1")
    verifyEq(san.toStr, "registeredId:1.2.840.113549.1.9.1")
  }

  Void testDirName()
  {
    san := San.dirName("cn=fantom")

    verifyEq(((SanType)san.type).tagId, 4)
    verifyEq(san.type, SanType.dirName)
    verify(san.val is Str)
    verifyEq(san.val, "cn=fantom")
    verifyEq(san.toStr, "dirName:cn=fantom")
  }

}
