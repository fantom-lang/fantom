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

  Void testIsToken()
  {
    verifyEq(WebUtil.isToken(""), false)
    verifyEq(WebUtil.isToken("x"), true)
    verifyEq(WebUtil.isToken("x y"), false)
    verifyEq(WebUtil.isToken("5a-3dd_33*&^%22!~"), true)
    verifyEq(WebUtil.isToken("(foo)"), false)
    verifyEq(WebUtil.isToken("foo;bar"), false)
  }

  Void testToQuotedStr()
  {
    verifyQuotedStr("", "\"\"")
    verifyQuotedStr("foo bar", "\"foo bar\"")
    verifyQuotedStr("foo\"bar\"baz", "\"foo\\\"bar\\\"baz\"")

    verifyErr(ArgErr#) |,| { WebUtil.toQuotedStr("foo\nbar") }
    verifyErr(ArgErr#) |,| { WebUtil.toQuotedStr("\u007f") }
    verifyErr(ArgErr#) |,| { WebUtil.toQuotedStr("\u024a") }

    verifyErr(ArgErr#) |,| { WebUtil.fromQuotedStr("") }
    verifyErr(ArgErr#) |,| { WebUtil.fromQuotedStr("\"") }
    verifyErr(ArgErr#) |,| { WebUtil.fromQuotedStr("\"x") }
    verifyErr(ArgErr#) |,| { WebUtil.fromQuotedStr("x\"") }
  }

  Void verifyQuotedStr(Str s, Str expected)
  {
    verifyEq(WebUtil.toQuotedStr(s), expected)
    verifyEq(WebUtil.fromQuotedStr(expected), s)
  }

  Void testParseList()
  {
    verifyEq(WebUtil.parseList("a"), ["a"])
    verifyEq(WebUtil.parseList(" a "), ["a"])
    verifyEq(WebUtil.parseList("a, bob, c,delta "), ["a", "bob", "c", "delta"])
  }

  Void testParseHeaders()
  {
    in :=
      ("Host: foobar\r\n" +
      "Extra1:  space\r\n" +
      "Extra2: space  \r\n" +
      "Cont: one two \r\n" +
      "  three\r\n" +
      "\tfour\r\n" +
      "Coalesce: a,b\r\n" +
      "Coalesce: c\r\n" +
      "Coalesce:  d\r\n" +
      "\r\n").in

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
    in := WebUtil.makeChunkedInStream(str.in)
    verifyEq(in.readAllStr, "xyzhello there")

    // readBuf chunks
    in = WebUtil.makeChunkedInStream(str.in)
    buf := Buf()
    verifyEq(in.readBuf(buf.clear, 20), 3)
    verifyEq(buf.flip.readAllStr, "xyz")
    verifyEq(in.readBuf(buf.clear, 20), 11)
    verifyEq(buf.flip.readAllStr, "hello there")
    verifyEq(in.readBuf(buf.clear, 20), null)

    // readBufFully
    in = WebUtil.makeChunkedInStream(str.in)
    in.readBufFully(buf.clear, 14)
    verifyEq(buf.readAllStr, "xyzhello there")
    verifyEq(in.read, null)

    // unread
    in = WebUtil.makeChunkedInStream(str.in)
    verifyEq(in.read, 'x')
    verifyEq(in.read, 'y')
    in.unread('?')
    verifyEq(in.read, '?')
    in.unread('2').unread('1')
    in.readBufFully(buf.clear, 14)
    verifyEq(buf.readAllStr, "12zhello there")

    // fixed chunked stream
    in = WebUtil.makeFixedInStream("abcdefgh".in, 3)
    verifyEq(in.readAllStr, "abc")
  }

  Void testFixedOutStream()
  {
    buf := Buf()
    out := WebUtil.makeFixedOutStream(buf.out, 4)
    out.print("abcd")
    verifyErr(IOErr#) |,| { out.write('x') }
    verifyEq(buf.flip.readAllStr, "abcd")

    buf2 := Buf()
    buf.seek(0)
    out = WebUtil.makeFixedOutStream(buf2.out, 2)
    out.writeBuf(buf, 2)
    verifyErr(IOErr#) |,| { out.writeBuf(buf, 1) }
    verifyEq(buf2.flip.readAllStr, "ab")
  }

  Void testChunkOutStream()
  {
    buf := Buf()
    out := WebUtil.makeChunkedOutStream(buf.out)
    2000.times |Int i| { out.printLine(i) }
    out.close

    in := WebUtil.makeChunkedInStream(buf.flip.in)
    2000.times |Int i| { verifyEq(in.readLine, i.toStr) }
    verifyEq(in.read, null)
  }

}