//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 06  Andy Frank  Creation
//

**
** UserAgentTest.
**
class UserAgentTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  Void testParsing()
  {
    ua := UserAgent.fromStr("Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-US) "
      + "AppleWebKit/125.4 (KHTML, like Gecko, Safari) OmniWeb/v563.57")

    verifyEq(ua.tokens[0], "Mozilla/5.0")
    verifyEq(ua.tokens[1], "(Macintosh; U; PPC Mac OS X; en-US)")
    verifyEq(ua.tokens[2], "AppleWebKit/125.4")
    verifyEq(ua.tokens[3], "(KHTML, like Gecko, Safari)")
    verifyEq(ua.tokens[4], "OmniWeb/v563.57")
  }

//////////////////////////////////////////////////////////////////////////
// Version
//////////////////////////////////////////////////////////////////////////

  Void testVersions()
  {
    ua := UserAgent.fromStr("")
    verifyEq(ua.parseVer("7.0"),    Version.fromStr("7.0"))
    verifyEq(ua.parseVer("7.0b"),   Version.fromStr("7.0"))
    verifyEq(ua.parseVer("7.0.a"),  Version.fromStr("7.0"))
    verifyEq(ua.parseVer("2.1a2"),  Version.fromStr("2.1"))
    verifyEq(ua.parseVer("1b"),     Version.fromStr("1"))
    verifyEq(ua.parseVer("abc"),    null)
    verifyEq(ua.parseVer("21.543"),   Version.fromStr("21.543"))
    verifyEq(ua.parseVer("21.543.a"), Version.fromStr("21.543"))
  }

//////////////////////////////////////////////////////////////////////////
// Browser Detection
//////////////////////////////////////////////////////////////////////////

  Void testBrowserDetection()
  {
    //
    // IE
    //
    ie :=
    [
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; Arcor 5.005; .NET CLR 1.0.3705; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)"
    ]
    // UA match
    verifyIE(ie)
    // Ver match
    verifyVerEq(ie[0], "5.5")
    verifyVerEq(ie[1], "6.0")
    verifyVerEq(ie[2], "7.0") // 7.0b
    verifyVerEq(ie[3], "7.0")
    verifyVerEq(ie[4], "8.0")
    // Ver is
    verifyVerIs(ie[0], "4.0", true)
    verifyVerIs(ie[0], "5",   true)
    verifyVerIs(ie[0], "5.5", true)
    verifyVerIs(ie[0], "6",   false)
    verifyVerIs(ie[0], "6.0", false)


    //
    // Firefox
    //
    firefox :=
    [
      "Mozilla/5.0 (Windows; U; Windows NT 5.1; nl-NL; rv:1.7.5) Gecko/20041202 Firefox/1.0",
      "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1",
      "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8) Gecko/20060321 Firefox/2.0a1",
    ]
    // UA match
    verifyFirefox(firefox)
    // Ver match
    verifyVerEq(firefox[0], "1.0")
    verifyVerEq(firefox[1], "1.5.0.1")
    verifyVerEq(firefox[2], "2.0") // 2.0a1
    // Ver is
    verifyVerIs(firefox[0], "1.0",     true)
    verifyVerIs(firefox[0], "1.0.1",   false)
    verifyVerIs(firefox[0], "1.1",     false)
    verifyVerIs(firefox[0], "1.5.0.1", false)
    verifyVerIs(firefox[0], "2.0",     false) // 2.0a1
    verifyVerIs(firefox[1], "1",   true)
    verifyVerIs(firefox[1], "1.1", true)
    verifyVerIs(firefox[1], "1.5", true)
    verifyVerIs(firefox[1], "2",   false)
    verifyVerIs(firefox[1], "2.0", false) // 2.0a1
    verifyVerIs(firefox[2], "1.5", true)
    verifyVerIs(firefox[2], "2",   true)
    verifyVerIs(firefox[2], "2.0", true)
    verifyVerIs(firefox[2], "3.0", false)

    //
    // Safari
    //
    safari :=
    [
      "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/124 (KHTML, like Gecko) Safari/125",
      "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/312.1 (KHTML, like Gecko) Safari/312",
      "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/412 (KHTML, like Gecko) Safari/412",
    ]
    // UA match
    verifySafari(safari)
    // Ver match
    verifyVerEq(safari[0], "125")
    verifyVerEq(safari[1], "312")
    verifyVerEq(safari[2], "412")
    // Ver is
    verifyVerIs(safari[0], "100", true)
    verifyVerIs(safari[0], "125", true)
    verifyVerIs(safari[0], "312", false)

    //
    // Opera
    //
    opera :=
    [
      "Opera/7.23 (Windows 98; U) [en]",
      "Opera/8.50 (Windows NT 5.1; U; en)",
      "Opera/9.00 (Windows NT 5.2; U; en)"
    ]
    // UA match
    verifyOpera(opera)
    // Ver match
    verifyVerEq(opera[0], "7.23")
    verifyVerEq(opera[1], "8.50")
    verifyVerEq(opera[2], "9.00")
    // Ver is
    verifyVerIs(opera[0], "7", true)
    verifyVerIs(opera[0], "7.2", true)
    verifyVerIs(opera[0], "7.23", true)
    verifyVerIs(opera[0], "7.24", false)
  }

  Void verifyIE(Str[] s)
  {
    s.each |Str str|
    {
      ua := UserAgent.fromStr(str)
      verifyEq(ua.isIE,      true)
      verifyEq(ua.isFirefox, false)
      verifyEq(ua.isSafari,  false)
      verifyEq(ua.isOpera,   false)
    }
  }

  Void verifyFirefox(Str[] s)
  {
    s.each |Str str|
    {
      ua := UserAgent.fromStr(str)
      verifyEq(ua.isIE,      false)
      verifyEq(ua.isFirefox, true)
      verifyEq(ua.isSafari,  false)
      verifyEq(ua.isOpera,   false)
    }
  }

  Void verifySafari(Str[] s)
  {
    s.each |Str str|
    {
      ua := UserAgent.fromStr(str)
      verifyEq(ua.isIE,      false)
      verifyEq(ua.isFirefox, false)
      verifyEq(ua.isSafari,  true)
      verifyEq(ua.isOpera,   false)
    }
  }

  Void verifyOpera(Str[] s)
  {
    s.each |Str str|
    {
      ua := UserAgent.fromStr(str)
      verifyEq(ua.isIE,      false)
      verifyEq(ua.isFirefox, false)
      verifyEq(ua.isSafari,  false)
      verifyEq(ua.isOpera,   true)
    }
  }

  Void verifyVerEq(Str s, Str v)
  {
    verifyEq(UserAgent.fromStr(s).version, Version.fromStr(v))
  }

  Void verifyVerIs(Str s, Str v, Bool m)
  {
    verifyEq(UserAgent.fromStr(s).version >= Version.fromStr(v), m)
  }

}