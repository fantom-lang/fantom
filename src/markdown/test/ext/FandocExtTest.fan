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
  private static const HtmlRenderer renderer := HtmlRenderer.builder.extensions(exts).build

  Void testFanCode()
  {
    verifyEq(render("'code'"), "<p><code>code</code></p>\n")
    verifyEq(render("this is 'fandoc' code"), "<p>this is <code>fandoc</code> code</p>\n")
    verifyEq(render("not 'fandoc code"), "<p>not 'fandoc code</p>\n")
    verifyEq(render("empty '' code"), "<p>empty <code></code> code</p>\n")
  }

  override protected Str render(Str source)
  {
    renderer.render(parser.parse(source))
  }
}