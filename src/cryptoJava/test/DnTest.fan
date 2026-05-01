//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//   16 Apr 2026 Ross Schwalm       Expand test cases
//

class DnTest : Test
{

  Void testRfc4514Type()
  {
    verifyEq("CN", parse("cn=foo").first.shortName)
    verifyNull(parse("0.0.40.9999=foo").first.shortName)

    verifyErr(ParseErr#) { parse("00.1=foo") }
    verifyErr(ParseErr#) { parse("0.01=foo") }
    verifyErr(ParseErr#) { parse("0.0.=foo") }
  }

  Void testRfc4514Val()
  {
    verifyEq("foo", parse("cn=foo").first.val)
  }

  Void testWithComplexDnUnorderedRandomCase()
  {
    subjectDn := "cn=Test,Ou=Engineering,o=Example Corp,ST=Virginia,c=US"
    parsed := parse(subjectDn)
    verifyEq(parsed.map |rdn->Str| { rdn.toStr }, ["CN=Test", "OU=Engineering", "O=Example Corp", "ST=Virginia", "C=US"])
    normalized := Dn.fromStr(subjectDn).toStr
    verifyEq(normalized, "C=US,ST=Virginia,O=Example Corp,OU=Engineering,CN=Test")
  }

  Void testValueCase()
  {
    subjectDn := "cn=test,ou=Engineering,o=Example corp,st=virginia,c=us"
    normalized := Dn.fromStr(subjectDn).toStr
    verifyEq(normalized, "C=us,ST=virginia,O=Example corp,OU=Engineering,CN=test")
  }

  Void testWithStateNormaliztion()
  {
    subjectDn := "cn=Test,ou=Engineering,o=Example Corp,s=Virginia,c=US"
    parsed := Dn.fromStr(subjectDn).toStr
    verifyEq(parsed.toStr, "C=US,ST=Virginia,O=Example Corp,OU=Engineering,CN=Test")
  }  

  Void testInvalidDn()
  {
    subjectDn := "cn=Test, ou=Engineering, o=Example Corp, s=Virginia, c=US"
    verifyErr(ParseErr#) { parse(subjectDn) }
    verifyErr(ParseErr#) { Dn.fromStr(subjectDn).toStr }
    parsed := Dn.fromStr(subjectDn,false).toStr
    verifyEq(parsed.toStr, subjectDn)
  }

  Void testCheckedParameterTrue()
  {
    verifyErr(ParseErr#) { Dn.fromStr("INVALID DN FORMAT").toStr }
    verifyErr(ParseErr#) { Dn.fromStr("INVALID DN FORMAT", true).toStr }
  }

  Void testCheckedParameterFalse()
  {
    invalid := "COMPLETELY@INVALID#DN"
    dn := Dn.fromStr(invalid, false)
    verifyEq(dn.toStr, invalid)
    verifyEq(dn.rawStr, invalid)
    verifyEq(dn.rdns.size, 0)
  }

  Void testOidPrefixSupport()
  {
    dn := "CN=SOME CA,OID.2.5.4.97=ABCDE-F12345G,O=ABCD-CORP,C=US"
    parsed := Dn.fromStr(dn)
    verify(parsed.rdns.size > 0)
    
    normalized := parsed.toStr
    verify(normalized.contains("C=US"))
    verify(normalized.contains("O=ABCD-CORP"))
    verify(normalized.contains("CN=SOME CA"))
  }

  Void testQuotedValues()
  {
    // Test quoted values with commas (Java X500Principal format)
    dn := """OU=ePKI Root,O="Fictional Telecom Co.,Ltd.",C=US"""
    parsed := Dn.fromStr(dn)
    verifyEq(parsed.rdns.size, 3)
    
    oRdn := parsed.rdns.find { it.shortName == "O" }
    verifyNotNull(oRdn)
    verifyEq(oRdn.val, "Fictional Telecom Co.,Ltd.")
  }

  Void testEmailAddressKeyword()
  {
    // Test both EMAIL and EMAILADDRESS keywords parse successfully
    dn1 := "EMAIL=test@example.com,CN=Test,O=Example"
    parsed1 := Dn.fromStr(dn1)
    verifyEq(parsed1.rdns.size, 3)
    
    dn2 := "EMAILADDRESS=info@example.com,CN=Test,O=Example"
    parsed2 := Dn.fromStr(dn2)
    verifyEq(parsed2.rdns.size, 3)
    
    // Both should map to the same OID - find by value
    email1 := parsed1.rdns.find { it.val == "test@example.com" }
    email2 := parsed2.rdns.find { it.val == "info@example.com" }
    verifyNotNull(email1)
    verifyNotNull(email2)
    
    // Verify they both map to PKCS#9 email OID
    verifyEq(email1.type.oidStr, "1.2.840.113549.1.9.1")
    verifyEq(email2.type.oidStr, "1.2.840.113549.1.9.1")
  }

  Void testSpacesAfterCommasError()
  {
    dn := "CN=Test, OU=Engineering"
    try
    {
      Dn.fromStr(dn).toStr
      fail("Expected ParseErr")
    }
    catch (ParseErr e)
    {
      // Verify error message mentions spaces and shows correct format
      verifyTrue(e.msg.contains("Spaces are not allowed"))
      verifyTrue(e.msg.contains("RFC 4514"))
    }
  }

  Void testStateNormalizationSToST()
  {
    dn := "CN=Test,S=Virginia,O=Example"
    parsed := Dn.fromStr(dn)
    normalized := parsed.toStr
    
    verifyTrue(normalized.contains("ST=Virginia"))
    verifyFalse(normalized.contains("S=Virginia"))
  }

  Void testComplexRealWorldDn()
  {
    // Test a complex real-world DN with multiple features
    dn := """EMAILADDRESS=info@e-szigno.hu,CN=Microsec e-Szigno Root CA 2009,O="Microsec Ltd.",L=Budapest,C=HU"""
    parsed := Dn.fromStr(dn)
    
    verify(parsed.rdns.size >= 5)
    
    normalized := parsed.toStr
    verifyTrue(normalized.startsWith("C=HU"))
    verify(normalized.contains("CN=Microsec"))
  }

  Void testUncheckedPreservesValidDn()
  {
    dn := "CN=Test,OU=Engineering,O=Example,C=US"
    parsed := Dn.fromStr(dn, false)
    
    verifyEq(parsed.rdns.size, 4)
    verifyNull(parsed.rawStr)
    
    normalized := parsed.toStr
    verifyEq(normalized, "C=US,O=Example,OU=Engineering,CN=Test")
  }

  private Rdn[] parse(Str name)
  {
    DnParser(name).parse
  }

}