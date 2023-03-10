//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//

**
** CharsetTest
**
@Js
class CharsetTest : Test
{

  Void testDefVal()
  {
    verifySame(Charset.defVal, Charset.utf8)
    verifySame(Charset#.make, Charset.utf8)
  }

  Void testIdentity()
  {
    // verify name, toStr, equals, hash

    c1 := Charset.fromStr("UTF-8")
    verifyType(c1, Charset#)
    verifyEq(Type.of(c1).base, Obj#)
    verifyEq(c1.name,  "UTF-8")
    verifyEq(c1.toStr, "UTF-8")

    c2 := Charset.fromStr("utf-8")
    verifyEq(c2.name,  "UTF-8")
    verifyEq(c2.toStr, "UTF-8")

    verifyEq(c1, c2)
    verifyEq(c1.hash, c2.hash)
    verifyNotEq(c1, "foo")

    // verify invalid name
    verifyEq(Charset.fromStr("bogus", false), null)
    verifyErr(ParseErr#) { x := Charset.fromStr("bogus") }
    verifyErr(ParseErr#) { x := Charset.fromStr("*^%#!%", true) }
  }

  Void testStandard()
  {
    // verify standard char encodings
    verifyEq(Charset.utf8().name,   "UTF-8")
    verifySame(Charset.fromStr("UTF-8"), Charset.utf8())
    verifySame(Charset.fromStr("utf-8"), Charset.utf8())

    verifyEq(Charset.utf16BE().name, "UTF-16BE")
    verifySame(Charset.fromStr("UTF-16BE"), Charset.utf16BE())
    verifySame(Charset.fromStr("utf-16be"), Charset.utf16BE())

    verifyEq(Charset.utf16LE().name, "UTF-16LE")
    verifySame(Charset.fromStr("UTF-16LE"), Charset.utf16LE())
    verifySame(Charset.fromStr("utf-16le"), Charset.utf16LE())
  }

  Void testInStreamNesting()
  {
    str := "\u2022 hello world \u2022"

    // start with binary buffer
    buf := Buf()
    out := buf.out
    out.charset = Charset.utf16BE
    out.print(str)

    // verify wrapped stream does not change underlying stream
    in1 := buf.flip.in
    in2 := CharsetTestInStream(in1)
    in2.charset = Charset.utf16BE
    verifyEq(in2.readAllStr, str)
    verifyEq(in1.charset, Charset.utf8)
    verifyEq(in2.charset, Charset.utf16BE)

    // now test with StrInStream which used rChar differently
    in1 = str.in
    in2 = CharsetTestInStream(in1)
    in2.charset = Charset.utf16BE
    verifyEq(in2.readAllStr, str)
    verifyEq(in1.charset, Charset.utf8)
    verifyEq(in2.charset, Charset.utf16BE)

    // now wrap a stream that has its charset set and verify
    // wrapped stream takes its configuration
    in1 = buf.seek(0).in
    in1.charset = Charset.utf16BE
    in2 = CharsetTestInStream(in1)
    verifyEq(in2.readAllStr, str)
    verifyEq(in1.charset, Charset.utf16BE)
    verifyEq(in2.charset, Charset.utf16BE)
  }

}

@Js
internal class CharsetTestInStream : InStream
{
  new make(InStream in) : super(in) {}
}