//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Nov 26  Brian Frank  Creation
//

**
** Base64VLQTest
**
class Base64VLQTest : Test
{
  Void test()
  {
    verifyEncode(0,     "A")
    verifyEncode(1,     "C")
    verifyEncode(-1,    "D")
    verifyEncode(15,    "e")
    verifyEncode(-15,   "f")
    verifyEncode(16,    "gB")
    verifyEncode(-16,   "hB")
    verifyEncode(31,    "+B")
    verifyEncode(-31,   "/B")
    verifyEncode(32,    "gC")
    verifyEncode(-32,   "hC")
    verifyEncode(511,   "+f")
    verifyEncode(-511,  "/f")
    verifyEncode(512,   "ggB")
    verifyEncode(-512,  "hgB")
    verifyEncode(1000,  "w+B")
    verifyEncode(-1000, "x+B")
    verifyEncode(65535, "+//D")
    verifyEncode(-65535, "///D")
    verifyEncode(2147483647, "+/////D")
    verifyEncode(-1099511627776, "hgggggggC")
  }

  Void verifyEncode(Int val, Str expected)
  {
    verifyEq(Base64VLQ.encode(val), expected)
  }
}
