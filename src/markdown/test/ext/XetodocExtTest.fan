//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

@Js
class XetodocExtTest : RenderingTest
{
  private static const Parser parser := Xetodoc.parser(TestLinkResolver())
  private static const HtmlRenderer renderer := Xetodoc.htmlRenderer
  private static const MarkdownRenderer md := Xetodoc.markdownRenderer

  Void testInlineCode()
  {
    // sanity check that backticks renders as inline code
    verifyEq(render("`code`"), "<p><code>code</code></p>\n")
  }

  Void testBracketLinks()
  {
    verifyEq(Xetodoc.toHtml("[a]"), """<p><a href="a">a</a></p>\n""")
    verifyEq(Xetodoc.toHtml("Use [now()] for timestamp"), """<p>Use <a href="now()">now()</a> for timestamp</p>\n""")
    verifyEq(Xetodoc.toHtml("Str[]"), """<p>Str[]</p>\n""")
  }

  // Void testBacktickLinks()
  // {
  //   // doc := parser.parse("`url`\n\n[url](url)\n\n![imgUrl](imgUrl)")
  //   // Node.dumpTree(doc)
  //   // echo("===")
  //   // echo(renderer.render(doc))
  // }

  Void testHeadingAnchor()
  {
    // simple test
    verifyEq(render("# Intro"), """<h1 id="intro">Intro</h1>\n""")

    // ignore formatting
    verifyEq(render("# _Intro_ Section"), """<h1 id="intro-section"><em>Intro</em> Section</h1>\n""")

    // handle duplicate section ids
    verifyEq(render("# Intro\n# Intro"), """<h1 id="intro">Intro</h1>\n<h1 id="intro-1">Intro</h1>\n""")

    // text and code mixed
    verifyEq(render("## `Heading` 2"), """<h2 id="heading-2"><code>Heading</code> 2</h2>\n""")

    // whacky symbols and spacing
    verifyEq(render("# Heading#!\tNoSpace!!!  "), """<h1 id="headingnospace">Heading#!\tNoSpace!!!</h1>\n""")
  }

  Void testIgnoreHtml()
  {
    verifyEq(render("Foo<h1>H1</h1>\n<h2>H2</h2>\n\nText"), "<p>FooH1</p>\n<p>Text</p>\n")
  }

  override protected Str render(Str source)
  {
    renderer.render(parser.parse(source))
  }
}

@Js
@NoDoc class TestLinkResolver : LinkResolver
{
  override Void resolve(LinkNode node)
  {
    node.destination = "/resolved"
    node.isCode = node is Link
    node.setText("resolved")
  }
}