//
// Copyright (c) 2019, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 19  Brian Frank  Creation
//

using inet

**
** WispTest
**
class WispTest : Test
{

  Void testExtraHeaders()
  {
    verifyExtraHeaders("", Str:Str[:])
    verifyExtraHeaders("  ", Str:Str[:])
    verifyExtraHeaders(Str<|a:b;c:d|>, Str:Str["a":"b", "c":"d"])
    verifyExtraHeaders(Str<|a : b ;  c : d |>, Str:Str["a":"b", "c":"d"])
    verifyExtraHeaders(Str<|a:"b"; c:"d"|>, Str:Str["a":"b", "c":"d"])
    verifyExtraHeaders(Str<|a:"i; j"; b:"foo; bar";|>, Str:Str["a":"i; j", "b":"foo; bar"])
    verifyExtraHeaders(Str<|Cookie:"v1; v2" ; Accept-Lang: "en-us; q=0.5"|>, ["Cookie": "v1; v2", "Accept-Lang": "en-us; q=0.5"])
    verifyExtraHeaders(Str<|Header-1:"Val"; Header-2:"Val";|>, ["Header-1":"Val", "Header-2":"Val"])

    // errors
    verifyExtraHeaders(Str<|a|>, null)
    verifyExtraHeaders(Str<|a:b;;c:d|>, null)
    verifyExtraHeaders(Str<|a: |>, null)
    verifyExtraHeaders(Str<|a:""|>, null)
  }

  Void verifyExtraHeaders(Str str, [Str:Str]? expected)
  {

    actual := Str:Str[:]
    if (expected == null)
    {
      verifyErr(Err#) { WispService.parseExtraHeaders(actual, str) }
    }
    else
    {
      WispService.parseExtraHeaders(actual, str)
      verifyEq(actual, expected)
    }
  }

}