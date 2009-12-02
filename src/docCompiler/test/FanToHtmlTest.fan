//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 08  Andy Frank  Creation
//

using fandoc

**
** FanToHtmlTest
**
class FanToHtmlTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testSafe()
  {
    verifyHtml("x && y", "x &amp;&amp; y")
    verifyHtml("x > y", "x &gt; y")
    verifyHtml("x < y", "x &lt; y")
  }

  Void testKeywords()
  {
    verifyHtml("abstract", "<span class='k'>abstract</span>")
    verifyHtml("as",       "<span class='k'>as</span>")
    verifyHtml("assert",   "<span class='k'>assert</span>")
    verifyHtml("finally",  "<span class='k'>finally</span>")
    verifyHtml("for",      "<span class='k'>for</span>")
    verifyHtml("foreach",  "<span class='k'>foreach</span>")
    verifyHtml("readonly", "<span class='k'>readonly</span>")
    verifyHtml("return",   "<span class='k'>return</span>")
    verifyHtml("static",   "<span class='k'>static</span>")
  }

  Void testChars()
  {
    verifyHtml("'a'",    "<span class='s'>'a'</span>")
    verifyHtml("'&'" ,   "<span class='s'>'&amp;'</span>")
    verifyHtml("'<'",    "<span class='s'>'&lt;'</span>")
    verifyHtml("'>'",    "<span class='s'>'&gt;'</span>")
    verifyHtml("'\\b'",  "<span class='s'>'\\b'</span>")
    verifyHtml("'\\t'",  "<span class='s'>'\\t'</span>")
    verifyHtml("'\\n'",  "<span class='s'>'\\n'</span>")
    verifyHtml("'\\f'",  "<span class='s'>'\\f'</span>")
    verifyHtml("'\\r'",  "<span class='s'>'\\r'</span>")
    verifyHtml("'\\\"'", "<span class='s'>'\\\"'</span>")
    verifyHtml(Str<|'\''|>, "<span class='s'>'\\''</span>")
    verifyHtml(Str<|'\\'|>, "<span class='s'>'\\\\'</span>")
  }

  Void testStrs()
  {
    verifyHtml("\"" + "foo" + "\"",         "<span class='s'>\"" + "foo" + "\"</span>")
    verifyHtml("\"" + "foo\\nbar" + "\"",    "<span class='s'>\"" + "foo\\nbar" + "\"</span>")
    verifyHtml("\"" + "foo\\tbar" + "\"",    "<span class='s'>\"" + "foo\\tbar" + "\"</span>")
    verifyHtml("\"" + "don't look" + "\"",  "<span class='s'>\"" + "don't look" + "\"</span>")
    verifyHtml("\"" + "don\\'t look" + "\"", "<span class='s'>\"" + "don\\'t look" + "\"</span>")
    verifyHtml("\"foo\\\"bar\"", "<span class='s'>\"foo\\\"bar\"</span>")
    verifyHtml("\"&\"",  "<span class='s'>\"&amp;\"</span>")
    verifyHtml("\"<\"",  "<span class='s'>\"&lt;\"</span>")
    verifyHtml("\">\"",  "<span class='s'>\"&gt;\"</span>")
    verifyHtml("\"" + Str<|\\|> + "\"", "<span class='s'>\"" + Str<|\\|> + "\"</span>")
  }

  Void testUris()
  {
    verifyHtml("`http://localhost`", "<span class='u'>`http://localhost`</span>")
  }

  Void testBrackets()
  {
    verifyHtml("[]", "<span class='b'>[]</span>")
    verifyHtml("{}", "<span class='b'>{}</span>")
    verifyHtml("()", "<span class='b'>()</span>")
    verifyHtml("[foo]", "<span class='b'>[</span>foo<span class='b'>]</span>")
    verifyHtml("{foo}", "<span class='b'>{</span>foo<span class='b'>}</span>")
    verifyHtml("(foo)", "<span class='b'>(</span>foo<span class='b'>)</span>")
    verifyHtml("[{()}]", "<span class='b'>[{()}]</span>")
  }

  Void testLineComments()
  {
    verifyHtml("x/5", "x/5")
    verifyHtml("x / 5", "x / 5")
    verifyHtml("// foo", "<span class='y'>// foo</span>")
    verifyHtml("// foo\n", "<span class='y'>// foo</span>\n")
    verifyHtml("// foo\n// bar\n", "<span class='y'>// foo</span>\n<span class='y'>// bar</span>\n")
    verifyHtml("// foo & bar\n", "<span class='y'>// foo &amp; bar</span>\n")
    verifyHtml("public // foo", "<span class='k'>public</span> <span class='y'>// foo</span>")
    verifyHtml("public//foo", "<span class='k'>public</span><span class='y'>//foo</span>")
  }

  Void testBlockComments()
  {
    verifyHtml("/* public foo() */", "<span class='x'>/* public foo() */</span>")
    verifyHtml("/* public foo() */\n", "<span class='x'>/* public foo() */</span>\n")
    verifyHtml("/* foo & bar */", "<span class='x'>/* foo &amp; bar */</span>")
    verifyHtml("/*foo*/public", "<span class='x'>/*foo*/</span><span class='k'>public</span>")
    verifyHtml("/* public /*foo()*/ */\n", "<span class='x'>/* public /*foo()*/ */</span>\n")
    verifyHtml("/*/*/**/*/*/", "<span class='x'>/*/*/**/*/*/</span>")
  }

  Void testFandocComments()
  {
    verifyHtml("x*5", "x*5")
    verifyHtml("x * 5", "x * 5")
    verifyHtml("** foo", "<span class='z'>** foo</span>")
    verifyHtml("** foo\n", "<span class='z'>** foo</span>\n")
    verifyHtml("** foo\n** bar\n", "<span class='z'>** foo</span>\n<span class='z'>** bar</span>\n")
    verifyHtml("** foo & bar\n", "<span class='z'>** foo &amp; bar</span>\n")
    verifyHtml("public ** foo", "<span class='k'>public</span> <span class='z'>** foo</span>")
    verifyHtml("public**foo", "<span class='k'>public</span><span class='z'>**foo</span>")
  }

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

  Void testComplex()
  {
    verifyHtml(
     "class Foo
      {
        // does this work?
        Int str := \"cool & \\\"foo\\\" > 'rock' < weee!\"
        Int x := 5  // andy rules!
      }
      ",

     "<span class='k'>class</span> Foo
      <span class='b'>{</span>
        <span class='y'>// does this work?</span>
        Int str := <span class='s'>\"cool &amp; \\\"foo\\\" &gt; 'rock' &lt; weee!\"</span>
        Int x := 5  <span class='y'>// andy rules!</span>
      <span class='b'>}</span>
      ")
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  Void verifyHtml(Str src, Str html)
  {
    //echo(html)
    in  := Buf.make.print(src).seek(0)
    out := Buf.make
    html = "<div class='src'>\n<pre>\n$html</pre>\n</div>\n"
    FanToHtml(in.in, out.out).parse
    verifyEq(html, out.flip.readAllStr)
  }

}