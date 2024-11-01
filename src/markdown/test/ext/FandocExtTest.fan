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
  override protected Str render(Str source)
  {
    fandoc := FandocExt()
    parser := Parser.builder.extensions([fandoc]).build
    renderer := HtmlRenderer.builder.extensions([fandoc]).build
    return renderer.render(parser.parse(source))
  }

  Void testFanCode()
  {
    verifyEq(render("'code'"), "<p><code>code</code></p>\n")
    verifyEq(render("this is 'fandoc' code"), "<p>this is <code>fandoc</code> code</p>\n")
  }
}