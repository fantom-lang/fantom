//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

@Js
class FandocExtTest : RenderingTest
{
  private static const MarkdownExt[] exts := [FandocExt()]
  private static const Parser parser := Parser.builder.extensions(exts).build
  private static const HtmlRenderer renderer
    // := HtmlRenderer.builder.extensions(exts).build
    := HtmlRenderer.builder.withLinkResolver(TestLinkResolver()).extensions(exts).build

  Void testTicks()
  {
    verifyEq(render("'code'"), "<p><code>code</code></p>\n")
    verifyEq(render("this is 'fandoc' code"), "<p>this is <code>fandoc</code> code</p>\n")
    verifyEq(render("not 'fandoc code"), "<p>not 'fandoc code</p>\n")
    verifyEq(render("empty '' code is not code"), "<p>empty '' code is not code</p>\n")

    verifyEq(render("finally ''this 'is' possible''"),"<p>finally <code>this 'is' possible</code></p>\n")

    // doc := parser.parse("``` fantom\nis this fenced code\n```")
    doc := parser.parse("```is this fenced code```")
    Node.dumpTree(doc)
    echo("===")
    echo(renderer.render(doc))
  }

  Void testBacktickLinks()
  {
    doc := parser.parse("`url`\n\n[url](url)\n\n![imgUrl](imgUrl)")
    Node.dumpTree(doc)
    echo("===")
    echo(renderer.render(doc))
  }

  override protected Str render(Str source)
  {
    renderer.render(parser.parse(source))
  }
}

@Js
internal const class TestLinkResolver : LinkResolver
{
  override Void resolve(LinkNode node)
  {
    node.destination = "/resolved"
    node.isCode = node is Link
    node.setText("resolved")
  }
}