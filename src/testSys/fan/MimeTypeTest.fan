//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 08  Brian Frank  Creation
//

**
** MimeTypeTest
**
class MimeTypeTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    verifyEq(MimeType("text/plain"), MimeType("text/plain"))
    verifyEq(MimeType("text/PLAIN"), MimeType("text/plain"))
    verifyEq(MimeType("TEXT/plain"), MimeType("text/plain"))
    verifyEq(MimeType("text/plain; a=b; C=d"), MimeType("text/plain;A = b;c = d;"))
    verifyNotEq(MimeType("text/html"), MimeType("text/plain"))
    verifyNotEq(MimeType("text/plain; charset=utf-8"), MimeType("text/plain; charset=us-ascii"))
    verifyNotEq(MimeType("x/y; a=b"), MimeType("x/y; a=B"))
  }

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

  Void testPredefined()
  {
    verifyPredefined("image", "gif")
    verifyPredefined("image", "png")
    verifyPredefined("image", "jpeg")
    verifyPredefined("text", "plain")
    verifyPredefined("text", "html")
    verifyPredefined("text", "xml")
    verifyPredefined("x-directory", "normal")
  }

  Void verifyPredefined(Str media, Str sub)
  {
    m := MimeType("$media/$sub")
    verifyEq(m.mediaType, media)
    verifyEq(m.subType, sub)
    verifyEq(m.toStr, "$media/$sub")
    verifyEq(m.params.isRO, true)
    verifyEq(m.params.size, 0)
    verifySame(m, MimeType(m.toStr))
  }

//////////////////////////////////////////////////////////////////////////
// FromStr
//////////////////////////////////////////////////////////////////////////

  Void testFromStr()
  {
    verifyFromStr("text/plain", "text", "plain", null)
    verifyFromStr("Text/PLAIN", "text", "plain", null)
    verifyFromStr("Text/Plain; charset=utf-8", "text", "plain", ["charset":"utf-8"])
    verifyFromStr("Text/Plain ; charset=utf-8", "text", "plain", ["charset":"utf-8"])
    verifyFromStr("Text/Plain; charset=utf-8;", "text", "plain", ["charset":"utf-8"])
    verifyFromStr("Text/Plain;charset=utf-8 ;", "text", "plain", ["charset":"utf-8"])
    verifyFromStr("Text/Plain; a=b; c=d", "text", "plain", ["a":"b", "c":"d"])
    verifyFromStr("Text/Plain; a=b ; c = d;", "text", "plain", ["a":"b", "c":"d"])
    verifyFromStr("Text/Plain; a=\"q\"", "text", "plain", ["a":"q"])
    verifyFromStr("Text/Plain; a=\"q;x\"", "text", "plain", ["a":"q;x"])
    verifyFromStr("a/b; foo=\"bar==baz;\"", "a", "b", ["foo":"bar==baz;"])
    verifyFromStr("a/b; foo = \"bar==baz;\"; x=z", "a", "b", ["foo":"bar==baz;", "x":"z"])
    verifyFromStr("a/b; Foo=\"Bar==Baz;\"; x = Z ; y=\"=;\" ;", "a", "b", ["Foo":"Bar==Baz;", "x":"Z", "y":"=;"])

    verifyFromStrBad("foo")
    verifyFromStrBad("a/b; x=")
    verifyFromStrBad("a/b; x=y; z")
    verifyFromStrBad("a/b; charset=foo (comment)")
  }

  Void verifyFromStr(Str s, Str media, Str sub, [Str:Str]? params)
  {
    if (params == null) params = Str:Str[:]
    t := MimeType.fromStr(s)
    verifyEq(t.toStr, s)
    verifyEq(t.mediaType, media)
    verifyEq(t.subType, sub)
    verifyEq(t.params, params)
    verifyEq(t.params.caseInsensitive, true)
    verifyEq(t.params.isRO, true)
  }

  Void verifyFromStrBad(Str s)
  {
    verifyEq(MimeType.fromStr(s, false), null)
    verifyErr(ParseErr#) |,| { MimeType.fromStr(s) }
    verifyErr(ParseErr#) |,| { MimeType.fromStr(s, true) }
  }

//////////////////////////////////////////////////////////////////////////
// ForExt
//////////////////////////////////////////////////////////////////////////

  Void testForExt()
  {
    verifyEq(MimeType.forExt("txt"), MimeType("text/plain"))
    verifyEq(MimeType.forExt("xml"), MimeType("text/xml"))
    verifyEq(MimeType.forExt("XML"), MimeType("text/xml"))
    verifyEq(MimeType.forExt("gif"), MimeType("image/gif"))
    verifyEq(MimeType.forExt("foobar"), null)
    //verifyEq(MimeType.forExt(null), null)
  }

//////////////////////////////////////////////////////////////////////////
// Charset
//////////////////////////////////////////////////////////////////////////

  Void testCharset()
  {
    verifyEq(MimeType("text/plain; charset=UTF-16BE").charset, Charset.utf16BE)
    verifyEq(MimeType("text/html").charset, Charset.utf8)
  }

}