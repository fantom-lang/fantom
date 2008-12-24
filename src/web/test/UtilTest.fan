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

  Void testChunkInStream()
  {
    str := "3\r\nxyz\r\nB\r\nhello there\r\n0\r\n\r\n"

    // readAllStr
    in := ChunkInStream(InStream.makeForStr(str))
    verifyEq(in.readAllStr, "xyzhello there")

    // readBuf chunks
    in = ChunkInStream(InStream.makeForStr(str))
    buf := Buf()
    verifyEq(in.readBuf(buf.clear, 20), 3)
    verifyEq(buf.flip.readAllStr, "xyz")
    verifyEq(in.readBuf(buf.clear, 20), 11)
    verifyEq(buf.flip.readAllStr, "hello there")
    verifyEq(in.readBuf(buf.clear, 20), null)

    // readBufFully
    in = ChunkInStream(InStream.makeForStr(str))
    in.readBufFully(buf.clear, 14)
    verifyEq(buf.readAllStr, "xyzhello there")
    verifyEq(in.read, null)

    // unread
    in = ChunkInStream(InStream.makeForStr(str))
    verifyEq(in.read, 'x')
    verifyEq(in.read, 'y')
    in.unread('?')
    verifyEq(in.read, '?')
    in.unread('2').unread('1')
    in.readBufFully(buf.clear, 14)
    verifyEq(buf.readAllStr, "12zhello there")

    // fixed chunked stream
    in = ChunkInStream(InStream.makeForStr("abcdefgh"), 3)
    verifyEq(in.readAllStr, "abc")
  }

}