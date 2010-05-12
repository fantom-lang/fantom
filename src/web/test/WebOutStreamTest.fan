//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 06  Andy Frank  Creation
//

**
** WebOutStreamTest
**
class WebOutStreamTest : Test
{

//////////////////////////////////////////////////////////////////////////
// General
//////////////////////////////////////////////////////////////////////////

  Void testGeneral()
  {
    buf := StrBuf()
    out := WebOutStream(buf.out)

    out.w("foo")
    verifyOut(buf, "foo")

    out.w(4)
    verifyOut(buf, "4")

    out.w(null)
    verifyOut(buf, "null")

    out.tab
    verifyOut(buf, "  ")
    out.tab(5)
    verifyOut(buf, "     ")

    // TODO
    // out.nl
    // out.docType
  }

//////////////////////////////////////////////////////////////////////////
// Xml
//////////////////////////////////////////////////////////////////////////

  Void testXml()
  {
    buf := Buf.make
    out := WebOutStream(buf.out)

    out.prolog
    verifyOut(buf, "<?xml version='1.0' encoding='UTF-8'?>")

    out.tag("bar")
    verifyOut(buf, "<bar>")

    out.tag("bar", "foo='zoo'")
    verifyOut(buf, "<bar foo='zoo'>")

    out.tag("bar", "foo='zoo'", true)
    verifyOut(buf, "<bar foo='zoo' />")

    out.tag("bar", null, true)
    verifyOut(buf, "<bar />")

    out.tagEnd("bar")
    verifyOut(buf, "</bar>")
  }

//////////////////////////////////////////////////////////////////////////
// Html markup
//////////////////////////////////////////////////////////////////////////

  Void testHtml()
  {
    buf := Buf.make
    out := WebOutStream(buf.out)

    out.html
    verifyOut(buf, "<html xmlns='http://www.w3.org/1999/xhtml'>")
    out.htmlEnd
    verifyOut(buf, "</html>")

    out.head
    verifyOut(buf, "<head>")
    out.headEnd
    verifyOut(buf, "</head>")

    out.title.w("Test").titleEnd
    verifyOut(buf, "<title>Test</title>")

    out.includeCss(`foo.css`)
    verifyOut(buf, "<link rel='stylesheet' type='text/css' href='foo.css' />")
    out.includeCss(`foo.css?a=foo&b=[bar]`)
    verifyOut(buf, "<link rel='stylesheet' type='text/css' href='foo.css?a=foo&amp;b=%5Bbar%5D' />")
    out.includeCss(`foo.css`)
    verifyOut(buf, null)

    out.includeJs(`foo.js`)
    verifyOut(buf, "<script type='text/javascript' src='foo.js'></script>")
    out.includeJs(`foo.js?a=foo&b=[bar]`)
    verifyOut(buf, "<script type='text/javascript' src='foo.js?a=foo&amp;b=%5Bbar%5D'></script>")
    out.includeJs(`foo.js`)
    verifyOut(buf, null)

    out.atom(`foo.xml`)
    verifyOut(buf, "<link rel='alternate' type='application/atom+xml' href='foo.xml' />")
    out.atom(`foo.xml?a=foo&b=[bar]`)
    verifyOut(buf, "<link rel='alternate' type='application/atom+xml' href='foo.xml?a=foo&amp;b=%5Bbar%5D' />")
    out.atom(`foo.xml`, "title='bar'")
    verifyOut(buf, "<link rel='alternate' type='application/atom+xml' href='foo.xml' title='bar' />")

    out.rss(`foo.xml`)
    verifyOut(buf, "<link rel='alternate' type='application/rss+xml' href='foo.xml' />")
    out.rss(`foo.xml?a=foo&b=[bar]`)
    verifyOut(buf, "<link rel='alternate' type='application/rss+xml' href='foo.xml?a=foo&amp;b=%5Bbar%5D' />")
    out.rss(`foo.xml`, "title='bar'")
    verifyOut(buf, "<link rel='alternate' type='application/rss+xml' href='foo.xml' title='bar' />")

    out.favIcon(`fav.png`)
    verifyOut(buf, "<link rel='icon' href='fav.png' />")
    out.favIcon(`fav.png`, "type='image/png'")
    verifyOut(buf, "<link rel='icon' href='fav.png' type='image/png' />")

    out.style
    verifyOut(buf, "<style type='text/css'>")
    out.style(null)
    verifyOut(buf, "<style>")
    out.styleEnd
    verifyOut(buf, "</style>")

    out.script
    verifyOut(buf, "<script type='text/javascript'>")
    out.script(null)
    verifyOut(buf, "<script>")
    out.scriptEnd
    verifyOut(buf, "</script>")

    //////////////////////////////////////////////////////////////////////////
    // General
    //////////////////////////////////////////////////////////////////////////

    out.body
    verifyOut(buf, "<body>")
    out.body("class='foo'")
    verifyOut(buf, "<body class='foo'>")
    out.bodyEnd
    verifyOut(buf, "</body>")

    out.h1.w("foo").h1End
    verifyOut(buf, "<h1>foo</h1>")
    out.h1("class='bar'").w("bar").h1End
    verifyOut(buf, "<h1 class='bar'>bar</h1>")

    out.h2.w("foo").h2End
    verifyOut(buf, "<h2>foo</h2>")
    out.h2("class='bar'").w("bar").h2End
    verifyOut(buf, "<h2 class='bar'>bar</h2>")

    out.h3.w("foo").h3End
    verifyOut(buf, "<h3>foo</h3>")
    out.h3("class='bar'").w("bar").h3End
    verifyOut(buf, "<h3 class='bar'>bar</h3>")

    out.h4.w("foo").h4End
    verifyOut(buf, "<h4>foo</h4>")
    out.h4("class='bar'").w("bar").h4End
    verifyOut(buf, "<h4 class='bar'>bar</h4>")

    out.h5.w("foo").h5End
    verifyOut(buf, "<h5>foo</h5>")
    out.h5("class='bar'").w("bar").h5End
    verifyOut(buf, "<h5 class='bar'>bar</h5>")

    out.h6.w("foo").h6End
    verifyOut(buf, "<h6>foo</h6>")
    out.h6("class='bar'").w("bar").h6End
    verifyOut(buf, "<h6 class='bar'>bar</h6>")

    out.div
    verifyOut(buf, "<div>")
    out.div("class='foo'")
    verifyOut(buf, "<div class='foo'>")
    out.divEnd
    verifyOut(buf, "</div>")

    out.span
    verifyOut(buf, "<span>")
    out.span("class='foo'")
    verifyOut(buf, "<span class='foo'>")
    out.spanEnd
    verifyOut(buf, "</span>")

    out.p
    verifyOut(buf, "<p>")
    out.p("class='foo'")
    verifyOut(buf, "<p class='foo'>")
    out.pEnd
    verifyOut(buf, "</p>")

    out.b
    verifyOut(buf, "<b>")
    out.b("class='foo'")
    verifyOut(buf, "<b class='foo'>")
    out.bEnd
    verifyOut(buf, "</b>")

    out.i
    verifyOut(buf, "<i>")
    out.i("class='foo'")
    verifyOut(buf, "<i class='foo'>")
    out.iEnd
    verifyOut(buf, "</i>")

    out.em
    verifyOut(buf, "<em>")
    out.em("class='foo'")
    verifyOut(buf, "<em class='foo'>")
    out.emEnd
    verifyOut(buf, "</em>")

    out.pre
    verifyOut(buf, "<pre>")
    out.pre("class='foo'")
    verifyOut(buf, "<pre class='foo'>")
    out.preEnd
    verifyOut(buf, "</pre>")

    out.code
    verifyOut(buf, "<code>")
    out.code("class='foo'")
    verifyOut(buf, "<code class='foo'>")
    out.codeEnd
    verifyOut(buf, "</code>")

    out.hr
    verifyOut(buf, "<hr />")

    out.br
    verifyOut(buf, "<br />")

    out.a(`#`)
    verifyOut(buf, "<a href='#'>")
    out.a(`/foo?a=foo&b=[bar]`)
    verifyOut(buf, "<a href='/foo?a=foo&amp;b=%5Bbar%5D'>")
    out.aEnd
    verifyOut(buf, "</a>")

    out.img(`foo.png`)
    verifyOut(buf, "<img src='foo.png' />")
    out.img(`foo.png?a=foo&b=[bar]`)
    verifyOut(buf, "<img src='foo.png?a=foo&amp;b=%5Bbar%5D' />")
    out.img(`foo.png`, "alt='bar'")
    verifyOut(buf, "<img src='foo.png' alt='bar' />")
    out.img(`foo.png`, "alt='bar' class='foo'")
    verifyOut(buf, "<img src='foo.png' alt='bar' class='foo' />")
    out.img(`foo.png`, "class='foo'")
    verifyOut(buf, "<img src='foo.png' class='foo' />")

    //////////////////////////////////////////////////////////////////////////
    // Table
    //////////////////////////////////////////////////////////////////////////

    out.table
    verifyOut(buf, "<table>")
    out.table("class='foo'")
    verifyOut(buf, "<table class='foo'>")
    out.tableEnd
    verifyOut(buf, "</table>")

    out.tr
    verifyOut(buf, "<tr>")
    out.tr("class='foo'")
    verifyOut(buf, "<tr class='foo'>")
    out.trEnd
    verifyOut(buf, "</tr>")

    out.th
    verifyOut(buf, "<th>")
    out.th("class='foo'")
    verifyOut(buf, "<th class='foo'>")
    out.thEnd
    verifyOut(buf, "</th>")

    out.td
    verifyOut(buf, "<td>")
    out.td("class='foo'")
    verifyOut(buf, "<td class='foo'>")
    out.tdEnd
    verifyOut(buf, "</td>")

    //////////////////////////////////////////////////////////////////////////
    // Lists
    //////////////////////////////////////////////////////////////////////////

    out.ul
    verifyOut(buf, "<ul>")
    out.ul("class='foo'")
    verifyOut(buf, "<ul class='foo'>")
    out.ulEnd
    verifyOut(buf, "</ul>")

    out.ol
    verifyOut(buf, "<ol>")
    out.ol("class='foo'")
    verifyOut(buf, "<ol class='foo'>")
    out.olEnd
    verifyOut(buf, "</ol>")

    out.li
    verifyOut(buf, "<li>")
    out.li("class='foo'")
    verifyOut(buf, "<li class='foo'>")
    out.liEnd
    verifyOut(buf, "</li>")

    //////////////////////////////////////////////////////////////////////////
    // Dictionary
    //////////////////////////////////////////////////////////////////////////

    out.dl
    verifyOut(buf, "<dl>")
    out.dl("class='foo'")
    verifyOut(buf, "<dl class='foo'>")
    out.dlEnd
    verifyOut(buf, "</dl>")

    out.dt
    verifyOut(buf, "<dt>")
    out.dt("class='foo'")
    verifyOut(buf, "<dt class='foo'>")
    out.dtEnd
    verifyOut(buf, "</dt>")

    out.dd
    verifyOut(buf, "<dd>")
    out.dd("class='foo'")
    verifyOut(buf, "<dd class='foo'>")
    out.ddEnd
    verifyOut(buf, "</dd>")

    //////////////////////////////////////////////////////////////////////////
    // Form
    //////////////////////////////////////////////////////////////////////////

    out.form
    verifyOut(buf, "<form>")
    out.form("class='foo'")
    verifyOut(buf, "<form class='foo'>")
    out.formEnd
    verifyOut(buf, "</form>")

    out.input
    verifyOut(buf, "<input />")
    out.input("class='foo'")
    verifyOut(buf, "<input class='foo' />")

    out.textField
    verifyOut(buf, "<input type='text' />")
    out.textField("class='foo'")
    verifyOut(buf, "<input type='text' class='foo' />")

    out.password
    verifyOut(buf, "<input type='password' />")
    out.password("class='foo'")
    verifyOut(buf, "<input type='password' class='foo' />")

    out.hidden
    verifyOut(buf, "<input type='hidden' />")
    out.hidden("class='foo'")
    verifyOut(buf, "<input type='hidden' class='foo' />")

    out.button
    verifyOut(buf, "<input type='button' />")
    out.button("class='foo'")
    verifyOut(buf, "<input type='button' class='foo' />")

    out.checkbox
    verifyOut(buf, "<input type='checkbox' />")
    out.checkbox("class='foo'")
    verifyOut(buf, "<input type='checkbox' class='foo' />")

    out.radio
    verifyOut(buf, "<input type='radio' />")
    out.radio("class='foo'")
    verifyOut(buf, "<input type='radio' class='foo' />")

    out.submit
    verifyOut(buf, "<input type='submit' />")
    out.submit("class='foo'")
    verifyOut(buf, "<input type='submit' class='foo' />")

    out.select
    verifyOut(buf, "<select>")
    out.select("class='foo'")
    verifyOut(buf, "<select class='foo'>")
    out.selectEnd
    verifyOut(buf, "</select>")

    out.option
    verifyOut(buf, "<option>")
    out.option("class='foo'")
    verifyOut(buf, "<option class='foo'>")
    out.optionEnd
    verifyOut(buf, "</option>")

    out.textArea
    verifyOut(buf, "<textarea>")
    out.textArea("rows='20' cols='50'")
    verifyOut(buf, "<textarea rows='20' cols='50'>")
    out.textAreaEnd
    verifyOut(buf, "</textarea>")
  }

//////////////////////////////////////////////////////////////////////////
// Xml
//////////////////////////////////////////////////////////////////////////

  Void testEsc()
  {
    verifyEsc(null, "null")
    verifyEsc(56, "56")
    verifyEsc("", "")
    verifyEsc("x", "x")
    verifyEsc("!@^%()", "!@^%()")
    verifyEsc("x>", "x>")
    verifyEsc("x>\u01bc", "x>\u01bc")
    verifyEsc(">", "&gt;")
    verifyEsc("]>", "]&gt;")
    verifyEsc("<>&\"'", "&lt;>&amp;&quot;&apos;")
    verifyEsc("foo&", "foo&amp;")
    verifyEsc("foo&bar", "foo&amp;bar")
    verifyEsc("&bar", "&amp;bar")
  }

  Void verifyEsc(Obj? input, Str match)
  {
    buf := Buf()
    out := WebOutStream(buf.out)
    out.esc(input)
    verifyEq(buf.flip.readAllStr, match)

    sb  := StrBuf()
    out = WebOutStream(sb.out)
    out.esc(input)
    verifyEq(sb.toStr, match)
  }

//////////////////////////////////////////////////////////////////////////
// verifyOut
//////////////////////////////////////////////////////////////////////////

  Void verifyOut(Obj bufOrStrBuf, Str? match)
  {
    if (bufOrStrBuf is Buf)
    {
      buf := (Buf)bufOrStrBuf
      buf.flip
      verifyEq(buf.readLine, match)
      buf.clear
    }
    else
    {
      buf := (StrBuf)bufOrStrBuf
      verifyEq(buf.toStr, match)
      buf.clear
    }
  }

}