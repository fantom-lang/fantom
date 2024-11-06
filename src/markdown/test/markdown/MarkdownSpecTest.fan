//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Nov 2024  Matthew Giannini  Creation
//

class MarkdownSpecTest : CommonMarkSpecTest
{
  private Parser parser := Parser()
  private MarkdownRenderer markdown_renderer := MarkdownRenderer()
  // the spec says url-escaping is optional, but the examples assume it is enabled
  private HtmlRenderer html_renderer := HtmlRenderer.builder.withPercentEncodeUrls(true).build

  protected override Example[] examplesToRun() { super.examplesToRun }

  protected override ExampleRes run(Example example)
  {
    Str? html
    try
    {
      md := markdown_renderer.render(parser.parse(example.markdown))
      html = html_renderer.render(parser.parse(md))
      verifyEq(example.html, html)
      return ExampleRes(example)
    }
    catch (Err err)
    {
      return ExampleRes(example, err, html)
    }
  }

}