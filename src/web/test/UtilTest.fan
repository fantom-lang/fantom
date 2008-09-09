//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 07  Brian Frank  Creation
//

**
** UtilTest
**
class UtilTest : Test
{

  Void testParseList()
  {
    verifyEq(WebUtil.parseList("a"), ["a"])
    verifyEq(WebUtil.parseList(" a "), ["a"])
    verifyEq(WebUtil.parseList("a, bob, c,delta "), ["a", "bob", "c", "delta"])
  }

  Void testParseHeaders()
  {
    in := InStream.makeForStr(
      "Host: foobar\r\n" +
      "Extra1:  space\r\n" +
      "Extra2: space  \r\n" +
      "Cont: one two \r\n" +
      "  three\r\n" +
      "\tfour\r\n" +
      "Coalesce: a,b\r\n" +
      "Coalesce: c\r\n" +
      "Coalesce:  d\r\n" +
      "\r\n")

     headers := WebUtil.parseHeaders(in)
     verifyEq(headers.caseInsensitive, true)
     verifyEq(headers,
       [
        "Host":     "foobar",
        "Extra1":   "space",
        "Extra2":   "space",
        "Cont":     "one two three four",
        "Coalesce": "a,b,c,d",
       ])
  }

}
