//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Oct 2024  Matthew Giannini  Creation
//

@Js
class EscTest : Test
{
  Void testUnescapeStr()
  {
    s := Str<|foo\bar|>
    verifyEq(s, Esc.unescapeStr(s))

    verifyEq("foo!bar", Esc.unescapeStr(Str<|foo\!bar|>))
    verifyEq("foo<bar", Esc.unescapeStr(Str<|foo&lt;bar|>))
    verifyEq("<elem>", Esc.unescapeStr(Str<|&lt;elem&gt;|>))
  }

  Void testEscapeHtml()
  {
    verifyEq("nothing to escape", Esc.escapeHtml("nothing to escape"))
    verifyEq("&amp;", Esc.escapeHtml("&"))
    verifyEq("&lt;", Esc.escapeHtml("<"))
    verifyEq("&gt;", Esc.escapeHtml(">"))
    verifyEq("&quot;", Esc.escapeHtml("\""))
    verifyEq("&lt; start", Esc.escapeHtml("< start"))
    verifyEq("end &gt;", Esc.escapeHtml("end >"))
    verifyEq("&lt; both &gt;", Esc.escapeHtml("< both >"))
    verifyEq("&lt; middle &amp; too &gt;", Esc.escapeHtml("< middle & too >"))
  }
}